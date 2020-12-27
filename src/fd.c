#include <fcntl.h>

int ro_fd (const char *path) {
    return open (path, O_RDONLY);
}
