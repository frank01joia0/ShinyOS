/*
 * shiny-efiboot — cria/atualiza uma entrada de boot UEFI (Boot####) e a coloca
 * em primeiro lugar no BootOrder, escrevendo direto no efivarfs.
 * É o mínimo do efibootmgr que o shiny-install precisa, para discos MBR.
 *
 * uso: shiny-efiboot <disco> <nº da partição> <caminho do .efi> <descrição>
 *  ex: shiny-efiboot /dev/sda 1 '\EFI\BOOT\BOOTX64.EFI' ShinyOS
 */
#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

/* de <linux/fs.h>, que o musl-gcc não enxerga sem os headers do kernel */
#ifndef FS_IOC_GETFLAGS
#define FS_IOC_GETFLAGS _IOR('f', 1, long)
#define FS_IOC_SETFLAGS _IOW('f', 2, long)
#endif
#ifndef FS_IMMUTABLE_FL
#define FS_IMMUTABLE_FL 0x00000010
#endif

#define EFIVARS "/sys/firmware/efi/efivars"
#define GLOBAL_GUID "8be4df61-93ca-11d2-aa0d-00e098032b8c"
#define VAR_ATTRS 0x7 /* NON_VOLATILE | BOOTSERVICE_ACCESS | RUNTIME_ACCESS */
#define LOAD_OPTION_ACTIVE 0x1

static void die(const char *msg)
{
    fprintf(stderr, "shiny-efiboot: %s%s%s\n", msg, errno ? ": " : "", errno ? strerror(errno) : "");
    exit(1);
}

static void put16(uint8_t *p, uint16_t v) { p[0] = v; p[1] = v >> 8; }
static void put32(uint8_t *p, uint32_t v) { put16(p, v); put16(p + 2, v >> 16); }
static void put64(uint8_t *p, uint64_t v) { put32(p, v); put32(p + 4, v >> 32); }
static uint32_t get32(const uint8_t *p) { return p[0] | p[1] << 8 | p[2] << 16 | (uint32_t)p[3] << 24; }

/* ASCII -> UCS-2 com terminador; devolve o nº de bytes escritos */
static size_t ucs2(uint8_t *out, const char *s)
{
    size_t n = 0;
    for (; *s; s++, n += 2)
        put16(out + n, (uint8_t)*s);
    put16(out + n, 0);
    return n + 2;
}

static ssize_t read_var(const char *name, uint8_t *buf, size_t len)
{
    char path[256];
    snprintf(path, sizeof(path), EFIVARS "/%s-" GLOBAL_GUID, name);
    int fd = open(path, O_RDONLY);
    if (fd < 0)
        return -1;
    ssize_t n = read(fd, buf, len);
    close(fd);
    return n;
}

/* efivarfs marca as variáveis existentes como imutáveis; tira a flag antes de gravar */
static void write_var(const char *name, const uint8_t *data, size_t len)
{
    char path[256];
    uint8_t buf[4096];
    int fd, flags;

    snprintf(path, sizeof(path), EFIVARS "/%s-" GLOBAL_GUID, name);
    fd = open(path, O_RDONLY);
    if (fd >= 0) {
        if (ioctl(fd, FS_IOC_GETFLAGS, &flags) == 0 && (flags & FS_IMMUTABLE_FL)) {
            flags &= ~FS_IMMUTABLE_FL;
            ioctl(fd, FS_IOC_SETFLAGS, &flags);
        }
        close(fd);
    }
    if (len + 4 > sizeof(buf))
        die("variável grande demais");
    put32(buf, VAR_ATTRS);
    memcpy(buf + 4, data, len);
    fd = open(path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (fd < 0)
        die(path);
    /* o efivarfs exige que a variável inteira venha num único write() */
    if (write(fd, buf, len + 4) != (ssize_t)(len + 4))
        die(path);
    close(fd);
}

int main(int argc, char **argv)
{
    uint8_t mbr[512], opt[1024], cur[1024], order[512];
    char name[16];
    int partno, num = -1;

    if (argc != 5) {
        fprintf(stderr, "uso: %s <disco> <partição> <caminho .efi> <descrição>\n", argv[0]);
        return 2;
    }
    if (access(EFIVARS, W_OK) != 0)
        die("efivarfs não está montado com escrita (" EFIVARS ")");

    partno = atoi(argv[2]);
    if (partno < 1 || partno > 4)
        die("só partições primárias MBR (1-4) são suportadas");

    int fd = open(argv[1], O_RDONLY);
    if (fd < 0 || read(fd, mbr, sizeof(mbr)) != (ssize_t)sizeof(mbr))
        die(argv[1]);
    close(fd);
    if (mbr[510] != 0x55 || mbr[511] != 0xaa)
        die("o disco não tem tabela MBR");

    const uint8_t *pe = mbr + 446 + 16 * (partno - 1);
    uint32_t disksig = get32(mbr + 440);
    uint32_t start = get32(pe + 8), size = get32(pe + 12);
    if (!disksig)
        die("o disco não tem assinatura MBR (offset 440)");
    if (!size)
        die("a partição não existe");

    /* Device path: HD(MBR) / File(path) / End */
    uint8_t dp[512];
    size_t dl = 0;
    memset(dp, 0, sizeof(dp));
    dp[0] = 0x04; dp[1] = 0x01; put16(dp + 2, 42);
    put32(dp + 4, partno);
    put64(dp + 8, start);
    put64(dp + 16, size);
    put32(dp + 24, disksig);           /* assinatura: 4 bytes + 12 zeros */
    dp[40] = 0x01;                     /* formato MBR */
    dp[41] = 0x01;                     /* assinatura do tipo MBR */
    dl = 42;
    size_t plen = ucs2(dp + dl + 4, argv[3]);
    dp[dl] = 0x04; dp[dl + 1] = 0x04; put16(dp + dl + 2, 4 + plen);
    dl += 4 + plen;
    dp[dl] = 0x7f; dp[dl + 1] = 0xff; put16(dp + dl + 2, 4);
    dl += 4;

    /* EFI_LOAD_OPTION */
    size_t ol = 0;
    put32(opt, LOAD_OPTION_ACTIVE);
    put16(opt + 4, dl);
    ol = 6;
    ol += ucs2(opt + ol, argv[4]);
    memcpy(opt + ol, dp, dl);
    ol += dl;

    /* Reaproveita uma entrada com a mesma descrição, senão pega o primeiro número livre */
    uint8_t desc[256];
    size_t desclen = ucs2(desc, argv[4]);
    for (int i = 0; i <= 0xffff; i++) {
        snprintf(name, sizeof(name), "Boot%04X", i);
        ssize_t n = read_var(name, cur, sizeof(cur));
        if (n < 0) {
            if (num < 0)
                num = i;
            if (i > 0x100)
                break;
            continue;
        }
        if (n >= (ssize_t)(10 + desclen) && memcmp(cur + 10, desc, desclen) == 0) {
            num = i;
            break;
        }
    }
    if (num < 0)
        die("nenhum número Boot#### livre");
    snprintf(name, sizeof(name), "Boot%04X", num);
    write_var(name, opt, ol);

    /* BootOrder: a nova entrada vai para a frente */
    ssize_t n = read_var("BootOrder", cur, sizeof(cur));
    size_t on = 0;
    put16(order, num);
    on = 2;
    for (ssize_t i = 4; i + 1 < n; i += 2) {
        uint16_t e = cur[i] | cur[i + 1] << 8;
        if (e != num && on + 2 <= sizeof(order)) {
            put16(order + on, e);
            on += 2;
        }
    }
    write_var("BootOrder", order, on);

    printf("%s: \"%s\" -> %s (partição %d)\n", name, argv[4], argv[3], partno);
    return 0;
}
