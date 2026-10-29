/*
 * shinyfetch — informações do sistema da ShinyOS
 * (sucessor do lunafetch da LunairOS)
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <pwd.h>
#include <sys/utsname.h>
#include <sys/statvfs.h>

#define C_ART   "\033[1;35m"
#define C_KEY   "\033[1;35m"
#define C_RESET "\033[0m"

static const char *logo[] = {
    "        .         ",
    "       / \\        ",
    "   ___/   \\___    ",
    "   \\  shiny  /    ",
    "    >   ✦   <     ",
    "   /___   ___\\    ",
    "       \\ /        ",
    "        '         ",
    "                  ",
};
#define LOGO_LINES (sizeof(logo) / sizeof(logo[0]))

static char lines[16][512];
static int nlines;

static void add(const char *key, const char *val)
{
    if (nlines >= 16 || !val || !*val)
        return;
    snprintf(lines[nlines++], sizeof(lines[0]), C_KEY "%s" C_RESET ": %s", key, val);
}

static void os_name(char *out, size_t len)
{
    FILE *f = fopen("/etc/os-release", "r");
    char buf[256];

    snprintf(out, len, "ShinyOS");
    if (!f)
        return;
    while (fgets(buf, sizeof(buf), f)) {
        if (strncmp(buf, "PRETTY_NAME=", 12) == 0) {
            char *v = buf + 12;
            v[strcspn(v, "\n")] = '\0';
            if (*v == '"') {
                v++;
                v[strcspn(v, "\"")] = '\0';
            }
            snprintf(out, len, "%s", v);
            break;
        }
    }
    fclose(f);
}

static void uptime_str(char *out, size_t len)
{
    FILE *f = fopen("/proc/uptime", "r");
    double secs = 0;
    long d, h, m;

    out[0] = '\0';
    if (!f)
        return;
    if (fscanf(f, "%lf", &secs) != 1)
        secs = 0;
    fclose(f);
    d = (long)secs / 86400;
    h = ((long)secs % 86400) / 3600;
    m = ((long)secs % 3600) / 60;
    if (d)
        snprintf(out, len, "%ldd %ldh %ldmin", d, h, m);
    else if (h)
        snprintf(out, len, "%ldh %ldmin", h, m);
    else
        snprintf(out, len, "%ldmin", m);
}

static void cpu_str(char *out, size_t len)
{
    FILE *f = fopen("/proc/cpuinfo", "r");
    char buf[512], model[256] = "";
    int cores = 0;

    out[0] = '\0';
    if (!f)
        return;
    while (fgets(buf, sizeof(buf), f)) {
        if (strncmp(buf, "processor", 9) == 0)
            cores++;
        else if (!model[0] && strncmp(buf, "model name", 10) == 0) {
            char *v = strchr(buf, ':');
            if (v) {
                v += 2;
                v[strcspn(v, "\n")] = '\0';
                snprintf(model, sizeof(model), "%s", v);
            }
        }
    }
    fclose(f);
    snprintf(out, len, "%s (%d)", model[0] ? model : "desconhecida", cores);
}

static void mem_str(char *out, size_t len)
{
    FILE *f = fopen("/proc/meminfo", "r");
    char buf[256];
    long total = 0, avail = 0;

    out[0] = '\0';
    if (!f)
        return;
    while (fgets(buf, sizeof(buf), f)) {
        sscanf(buf, "MemTotal: %ld kB", &total);
        sscanf(buf, "MemAvailable: %ld kB", &avail);
    }
    fclose(f);
    if (total)
        snprintf(out, len, "%ld MiB / %ld MiB", (total - avail) / 1024, total / 1024);
}

static void disk_str(char *out, size_t len)
{
    struct statvfs st;

    out[0] = '\0';
    if (statvfs("/", &st) != 0 || st.f_blocks == 0)
        return;
    unsigned long long total = (unsigned long long)st.f_blocks * st.f_frsize;
    unsigned long long used = (unsigned long long)(st.f_blocks - st.f_bfree) * st.f_frsize;
    snprintf(out, len, "%llu MiB / %llu MiB%s", used >> 20, total >> 20,
             access("/etc/shinyos/live", F_OK) == 0 ? " (live, na RAM)" : "");
}

int main(void)
{
    struct utsname u;
    struct passwd *pw = getpwuid(getuid());
    char host[128] = "", title[256], os[256], kernel[256], up[64], cpu[320], mem[64], disk[96];
    char *shell = getenv("SHELL");
    char *term = getenv("TERM");

    gethostname(host, sizeof(host) - 1);
    snprintf(title, sizeof(title), C_ART "%s" C_RESET "@" C_ART "%s" C_RESET,
             pw ? pw->pw_name : "?", host);
    os_name(os, sizeof(os));
    uname(&u);
    snprintf(kernel, sizeof(kernel), "%s %s", u.sysname, u.release);
    uptime_str(up, sizeof(up));
    cpu_str(cpu, sizeof(cpu));
    mem_str(mem, sizeof(mem));
    disk_str(disk, sizeof(disk));
    if (!shell && pw)
        shell = pw->pw_shell;

    snprintf(lines[nlines++], sizeof(lines[0]), "%s", title);
    snprintf(lines[nlines++], sizeof(lines[0]), "%s", "------------------");
    add("SO", os);
    add("Base", "independente (herdeira da LunairOS)");
    add("Kernel", kernel);
    add("Arquitetura", u.machine);
    add("Uptime", up);
    add("Shell", shell);
    add("Terminal", term);
    add("CPU", cpu);
    add("Memória", mem);
    add("Disco (/)", disk);

    putchar('\n');
    for (size_t i = 0; i < LOGO_LINES || i < (size_t)nlines; i++) {
        printf("  " C_ART "%s" C_RESET, i < LOGO_LINES ? logo[i] : logo[LOGO_LINES - 1]);
        if (i < (size_t)nlines)
            printf("  %s", lines[i]);
        putchar('\n');
    }
    printf("\n  ");
    for (int c = 0; c < 8; c++)
        printf("\033[4%dm   ", c);
    printf(C_RESET "\n\n");
    return 0;
}
