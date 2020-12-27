#include <fcntl.h>

int ro_fd (const char *path) {
    return open ("/tmp/8d83954fcf79453738dbeba9615a095bae9caed9-Logitech-Unifying-RQR12.10_B0032.cab", O_RDONLY);
}
