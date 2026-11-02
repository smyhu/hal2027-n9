/* glibc 2.10 on the N9 has no plain stat(); it lives in libc_nonshared.a
   as a wrapper around __xstat. */
struct stat;
extern int __xstat(int ver, const char *path, struct stat *buf);
int stat(const char *path, struct stat *buf) { return __xstat(3, path, buf); }
