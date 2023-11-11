
user/_test_2:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "../kernel/types.h"
#include "../kernel/stat.h"
#include "user.h"

int
main(int argc, char *argv[]) {
   0:	1141                	add	sp,sp,-16
   2:	e406                	sd	ra,8(sp)
   4:	e022                	sd	s0,0(sp)
   6:	0800                	add	s0,sp,16
    int x1= 1;
    if (fork()>0){
   8:	00000097          	auipc	ra,0x0
   c:	2b0080e7          	jalr	688(ra) # 2b8 <fork>
  10:	02a05063          	blez	a0,30 <main+0x30>
    }
    else{
        x1 = 3;
        exit(0);
    }
    printf(">>>>%d\n", x1);
  14:	4589                	li	a1,2
  16:	00000517          	auipc	a0,0x0
  1a:	7ca50513          	add	a0,a0,1994 # 7e0 <malloc+0xf0>
  1e:	00000097          	auipc	ra,0x0
  22:	61a080e7          	jalr	1562(ra) # 638 <printf>
    exit(0);
  26:	4501                	li	a0,0
  28:	00000097          	auipc	ra,0x0
  2c:	298080e7          	jalr	664(ra) # 2c0 <exit>
        exit(0);
  30:	4501                	li	a0,0
  32:	00000097          	auipc	ra,0x0
  36:	28e080e7          	jalr	654(ra) # 2c0 <exit>

000000000000003a <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  3a:	1141                	add	sp,sp,-16
  3c:	e406                	sd	ra,8(sp)
  3e:	e022                	sd	s0,0(sp)
  40:	0800                	add	s0,sp,16
  extern int main();
  main();
  42:	00000097          	auipc	ra,0x0
  46:	fbe080e7          	jalr	-66(ra) # 0 <main>
  exit(0);
  4a:	4501                	li	a0,0
  4c:	00000097          	auipc	ra,0x0
  50:	274080e7          	jalr	628(ra) # 2c0 <exit>

0000000000000054 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  54:	1141                	add	sp,sp,-16
  56:	e422                	sd	s0,8(sp)
  58:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  5a:	87aa                	mv	a5,a0
  5c:	0585                	add	a1,a1,1
  5e:	0785                	add	a5,a5,1
  60:	fff5c703          	lbu	a4,-1(a1)
  64:	fee78fa3          	sb	a4,-1(a5)
  68:	fb75                	bnez	a4,5c <strcpy+0x8>
    ;
  return os;
}
  6a:	6422                	ld	s0,8(sp)
  6c:	0141                	add	sp,sp,16
  6e:	8082                	ret

0000000000000070 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  70:	1141                	add	sp,sp,-16
  72:	e422                	sd	s0,8(sp)
  74:	0800                	add	s0,sp,16
  while(*p && *p == *q)
  76:	00054783          	lbu	a5,0(a0)
  7a:	cb91                	beqz	a5,8e <strcmp+0x1e>
  7c:	0005c703          	lbu	a4,0(a1)
  80:	00f71763          	bne	a4,a5,8e <strcmp+0x1e>
    p++, q++;
  84:	0505                	add	a0,a0,1
  86:	0585                	add	a1,a1,1
  while(*p && *p == *q)
  88:	00054783          	lbu	a5,0(a0)
  8c:	fbe5                	bnez	a5,7c <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  8e:	0005c503          	lbu	a0,0(a1)
}
  92:	40a7853b          	subw	a0,a5,a0
  96:	6422                	ld	s0,8(sp)
  98:	0141                	add	sp,sp,16
  9a:	8082                	ret

000000000000009c <strlen>:

uint
strlen(const char *s)
{
  9c:	1141                	add	sp,sp,-16
  9e:	e422                	sd	s0,8(sp)
  a0:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  a2:	00054783          	lbu	a5,0(a0)
  a6:	cf91                	beqz	a5,c2 <strlen+0x26>
  a8:	0505                	add	a0,a0,1
  aa:	87aa                	mv	a5,a0
  ac:	86be                	mv	a3,a5
  ae:	0785                	add	a5,a5,1
  b0:	fff7c703          	lbu	a4,-1(a5)
  b4:	ff65                	bnez	a4,ac <strlen+0x10>
  b6:	40a6853b          	subw	a0,a3,a0
  ba:	2505                	addw	a0,a0,1
    ;
  return n;
}
  bc:	6422                	ld	s0,8(sp)
  be:	0141                	add	sp,sp,16
  c0:	8082                	ret
  for(n = 0; s[n]; n++)
  c2:	4501                	li	a0,0
  c4:	bfe5                	j	bc <strlen+0x20>

00000000000000c6 <memset>:

void*
memset(void *dst, int c, uint n)
{
  c6:	1141                	add	sp,sp,-16
  c8:	e422                	sd	s0,8(sp)
  ca:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  cc:	ca19                	beqz	a2,e2 <memset+0x1c>
  ce:	87aa                	mv	a5,a0
  d0:	1602                	sll	a2,a2,0x20
  d2:	9201                	srl	a2,a2,0x20
  d4:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
  d8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
  dc:	0785                	add	a5,a5,1
  de:	fee79de3          	bne	a5,a4,d8 <memset+0x12>
  }
  return dst;
}
  e2:	6422                	ld	s0,8(sp)
  e4:	0141                	add	sp,sp,16
  e6:	8082                	ret

00000000000000e8 <strchr>:

char*
strchr(const char *s, char c)
{
  e8:	1141                	add	sp,sp,-16
  ea:	e422                	sd	s0,8(sp)
  ec:	0800                	add	s0,sp,16
  for(; *s; s++)
  ee:	00054783          	lbu	a5,0(a0)
  f2:	cb99                	beqz	a5,108 <strchr+0x20>
    if(*s == c)
  f4:	00f58763          	beq	a1,a5,102 <strchr+0x1a>
  for(; *s; s++)
  f8:	0505                	add	a0,a0,1
  fa:	00054783          	lbu	a5,0(a0)
  fe:	fbfd                	bnez	a5,f4 <strchr+0xc>
      return (char*)s;
  return 0;
 100:	4501                	li	a0,0
}
 102:	6422                	ld	s0,8(sp)
 104:	0141                	add	sp,sp,16
 106:	8082                	ret
  return 0;
 108:	4501                	li	a0,0
 10a:	bfe5                	j	102 <strchr+0x1a>

000000000000010c <gets>:

char*
gets(char *buf, int max)
{
 10c:	711d                	add	sp,sp,-96
 10e:	ec86                	sd	ra,88(sp)
 110:	e8a2                	sd	s0,80(sp)
 112:	e4a6                	sd	s1,72(sp)
 114:	e0ca                	sd	s2,64(sp)
 116:	fc4e                	sd	s3,56(sp)
 118:	f852                	sd	s4,48(sp)
 11a:	f456                	sd	s5,40(sp)
 11c:	f05a                	sd	s6,32(sp)
 11e:	ec5e                	sd	s7,24(sp)
 120:	1080                	add	s0,sp,96
 122:	8baa                	mv	s7,a0
 124:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 126:	892a                	mv	s2,a0
 128:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 12a:	4aa9                	li	s5,10
 12c:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 12e:	89a6                	mv	s3,s1
 130:	2485                	addw	s1,s1,1
 132:	0344d863          	bge	s1,s4,162 <gets+0x56>
    cc = read(0, &c, 1);
 136:	4605                	li	a2,1
 138:	faf40593          	add	a1,s0,-81
 13c:	4501                	li	a0,0
 13e:	00000097          	auipc	ra,0x0
 142:	19a080e7          	jalr	410(ra) # 2d8 <read>
    if(cc < 1)
 146:	00a05e63          	blez	a0,162 <gets+0x56>
    buf[i++] = c;
 14a:	faf44783          	lbu	a5,-81(s0)
 14e:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 152:	01578763          	beq	a5,s5,160 <gets+0x54>
 156:	0905                	add	s2,s2,1
 158:	fd679be3          	bne	a5,s6,12e <gets+0x22>
  for(i=0; i+1 < max; ){
 15c:	89a6                	mv	s3,s1
 15e:	a011                	j	162 <gets+0x56>
 160:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 162:	99de                	add	s3,s3,s7
 164:	00098023          	sb	zero,0(s3)
  return buf;
}
 168:	855e                	mv	a0,s7
 16a:	60e6                	ld	ra,88(sp)
 16c:	6446                	ld	s0,80(sp)
 16e:	64a6                	ld	s1,72(sp)
 170:	6906                	ld	s2,64(sp)
 172:	79e2                	ld	s3,56(sp)
 174:	7a42                	ld	s4,48(sp)
 176:	7aa2                	ld	s5,40(sp)
 178:	7b02                	ld	s6,32(sp)
 17a:	6be2                	ld	s7,24(sp)
 17c:	6125                	add	sp,sp,96
 17e:	8082                	ret

0000000000000180 <stat>:

int
stat(const char *n, struct stat *st)
{
 180:	1101                	add	sp,sp,-32
 182:	ec06                	sd	ra,24(sp)
 184:	e822                	sd	s0,16(sp)
 186:	e426                	sd	s1,8(sp)
 188:	e04a                	sd	s2,0(sp)
 18a:	1000                	add	s0,sp,32
 18c:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 18e:	4581                	li	a1,0
 190:	00000097          	auipc	ra,0x0
 194:	170080e7          	jalr	368(ra) # 300 <open>
  if(fd < 0)
 198:	02054563          	bltz	a0,1c2 <stat+0x42>
 19c:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 19e:	85ca                	mv	a1,s2
 1a0:	00000097          	auipc	ra,0x0
 1a4:	178080e7          	jalr	376(ra) # 318 <fstat>
 1a8:	892a                	mv	s2,a0
  close(fd);
 1aa:	8526                	mv	a0,s1
 1ac:	00000097          	auipc	ra,0x0
 1b0:	13c080e7          	jalr	316(ra) # 2e8 <close>
  return r;
}
 1b4:	854a                	mv	a0,s2
 1b6:	60e2                	ld	ra,24(sp)
 1b8:	6442                	ld	s0,16(sp)
 1ba:	64a2                	ld	s1,8(sp)
 1bc:	6902                	ld	s2,0(sp)
 1be:	6105                	add	sp,sp,32
 1c0:	8082                	ret
    return -1;
 1c2:	597d                	li	s2,-1
 1c4:	bfc5                	j	1b4 <stat+0x34>

00000000000001c6 <atoi>:

int
atoi(const char *s)
{
 1c6:	1141                	add	sp,sp,-16
 1c8:	e422                	sd	s0,8(sp)
 1ca:	0800                	add	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 1cc:	00054683          	lbu	a3,0(a0)
 1d0:	fd06879b          	addw	a5,a3,-48
 1d4:	0ff7f793          	zext.b	a5,a5
 1d8:	4625                	li	a2,9
 1da:	02f66863          	bltu	a2,a5,20a <atoi+0x44>
 1de:	872a                	mv	a4,a0
  n = 0;
 1e0:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 1e2:	0705                	add	a4,a4,1
 1e4:	0025179b          	sllw	a5,a0,0x2
 1e8:	9fa9                	addw	a5,a5,a0
 1ea:	0017979b          	sllw	a5,a5,0x1
 1ee:	9fb5                	addw	a5,a5,a3
 1f0:	fd07851b          	addw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 1f4:	00074683          	lbu	a3,0(a4)
 1f8:	fd06879b          	addw	a5,a3,-48
 1fc:	0ff7f793          	zext.b	a5,a5
 200:	fef671e3          	bgeu	a2,a5,1e2 <atoi+0x1c>
  return n;
}
 204:	6422                	ld	s0,8(sp)
 206:	0141                	add	sp,sp,16
 208:	8082                	ret
  n = 0;
 20a:	4501                	li	a0,0
 20c:	bfe5                	j	204 <atoi+0x3e>

000000000000020e <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 20e:	1141                	add	sp,sp,-16
 210:	e422                	sd	s0,8(sp)
 212:	0800                	add	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 214:	02b57463          	bgeu	a0,a1,23c <memmove+0x2e>
    while(n-- > 0)
 218:	00c05f63          	blez	a2,236 <memmove+0x28>
 21c:	1602                	sll	a2,a2,0x20
 21e:	9201                	srl	a2,a2,0x20
 220:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 224:	872a                	mv	a4,a0
      *dst++ = *src++;
 226:	0585                	add	a1,a1,1
 228:	0705                	add	a4,a4,1
 22a:	fff5c683          	lbu	a3,-1(a1)
 22e:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 232:	fee79ae3          	bne	a5,a4,226 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 236:	6422                	ld	s0,8(sp)
 238:	0141                	add	sp,sp,16
 23a:	8082                	ret
    dst += n;
 23c:	00c50733          	add	a4,a0,a2
    src += n;
 240:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 242:	fec05ae3          	blez	a2,236 <memmove+0x28>
 246:	fff6079b          	addw	a5,a2,-1
 24a:	1782                	sll	a5,a5,0x20
 24c:	9381                	srl	a5,a5,0x20
 24e:	fff7c793          	not	a5,a5
 252:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 254:	15fd                	add	a1,a1,-1
 256:	177d                	add	a4,a4,-1
 258:	0005c683          	lbu	a3,0(a1)
 25c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 260:	fee79ae3          	bne	a5,a4,254 <memmove+0x46>
 264:	bfc9                	j	236 <memmove+0x28>

0000000000000266 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 266:	1141                	add	sp,sp,-16
 268:	e422                	sd	s0,8(sp)
 26a:	0800                	add	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 26c:	ca05                	beqz	a2,29c <memcmp+0x36>
 26e:	fff6069b          	addw	a3,a2,-1
 272:	1682                	sll	a3,a3,0x20
 274:	9281                	srl	a3,a3,0x20
 276:	0685                	add	a3,a3,1
 278:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 27a:	00054783          	lbu	a5,0(a0)
 27e:	0005c703          	lbu	a4,0(a1)
 282:	00e79863          	bne	a5,a4,292 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 286:	0505                	add	a0,a0,1
    p2++;
 288:	0585                	add	a1,a1,1
  while (n-- > 0) {
 28a:	fed518e3          	bne	a0,a3,27a <memcmp+0x14>
  }
  return 0;
 28e:	4501                	li	a0,0
 290:	a019                	j	296 <memcmp+0x30>
      return *p1 - *p2;
 292:	40e7853b          	subw	a0,a5,a4
}
 296:	6422                	ld	s0,8(sp)
 298:	0141                	add	sp,sp,16
 29a:	8082                	ret
  return 0;
 29c:	4501                	li	a0,0
 29e:	bfe5                	j	296 <memcmp+0x30>

00000000000002a0 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2a0:	1141                	add	sp,sp,-16
 2a2:	e406                	sd	ra,8(sp)
 2a4:	e022                	sd	s0,0(sp)
 2a6:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
 2a8:	00000097          	auipc	ra,0x0
 2ac:	f66080e7          	jalr	-154(ra) # 20e <memmove>
}
 2b0:	60a2                	ld	ra,8(sp)
 2b2:	6402                	ld	s0,0(sp)
 2b4:	0141                	add	sp,sp,16
 2b6:	8082                	ret

00000000000002b8 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 2b8:	4885                	li	a7,1
 ecall
 2ba:	00000073          	ecall
 ret
 2be:	8082                	ret

00000000000002c0 <exit>:
.global exit
exit:
 li a7, SYS_exit
 2c0:	4889                	li	a7,2
 ecall
 2c2:	00000073          	ecall
 ret
 2c6:	8082                	ret

00000000000002c8 <wait>:
.global wait
wait:
 li a7, SYS_wait
 2c8:	488d                	li	a7,3
 ecall
 2ca:	00000073          	ecall
 ret
 2ce:	8082                	ret

00000000000002d0 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 2d0:	4891                	li	a7,4
 ecall
 2d2:	00000073          	ecall
 ret
 2d6:	8082                	ret

00000000000002d8 <read>:
.global read
read:
 li a7, SYS_read
 2d8:	4895                	li	a7,5
 ecall
 2da:	00000073          	ecall
 ret
 2de:	8082                	ret

00000000000002e0 <write>:
.global write
write:
 li a7, SYS_write
 2e0:	48c1                	li	a7,16
 ecall
 2e2:	00000073          	ecall
 ret
 2e6:	8082                	ret

00000000000002e8 <close>:
.global close
close:
 li a7, SYS_close
 2e8:	48d5                	li	a7,21
 ecall
 2ea:	00000073          	ecall
 ret
 2ee:	8082                	ret

00000000000002f0 <kill>:
.global kill
kill:
 li a7, SYS_kill
 2f0:	4899                	li	a7,6
 ecall
 2f2:	00000073          	ecall
 ret
 2f6:	8082                	ret

00000000000002f8 <exec>:
.global exec
exec:
 li a7, SYS_exec
 2f8:	489d                	li	a7,7
 ecall
 2fa:	00000073          	ecall
 ret
 2fe:	8082                	ret

0000000000000300 <open>:
.global open
open:
 li a7, SYS_open
 300:	48bd                	li	a7,15
 ecall
 302:	00000073          	ecall
 ret
 306:	8082                	ret

0000000000000308 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 308:	48c5                	li	a7,17
 ecall
 30a:	00000073          	ecall
 ret
 30e:	8082                	ret

0000000000000310 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 310:	48c9                	li	a7,18
 ecall
 312:	00000073          	ecall
 ret
 316:	8082                	ret

0000000000000318 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 318:	48a1                	li	a7,8
 ecall
 31a:	00000073          	ecall
 ret
 31e:	8082                	ret

0000000000000320 <link>:
.global link
link:
 li a7, SYS_link
 320:	48cd                	li	a7,19
 ecall
 322:	00000073          	ecall
 ret
 326:	8082                	ret

0000000000000328 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 328:	48d1                	li	a7,20
 ecall
 32a:	00000073          	ecall
 ret
 32e:	8082                	ret

0000000000000330 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 330:	48a5                	li	a7,9
 ecall
 332:	00000073          	ecall
 ret
 336:	8082                	ret

0000000000000338 <dup>:
.global dup
dup:
 li a7, SYS_dup
 338:	48a9                	li	a7,10
 ecall
 33a:	00000073          	ecall
 ret
 33e:	8082                	ret

0000000000000340 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 340:	48ad                	li	a7,11
 ecall
 342:	00000073          	ecall
 ret
 346:	8082                	ret

0000000000000348 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 348:	48b1                	li	a7,12
 ecall
 34a:	00000073          	ecall
 ret
 34e:	8082                	ret

0000000000000350 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 350:	48b5                	li	a7,13
 ecall
 352:	00000073          	ecall
 ret
 356:	8082                	ret

0000000000000358 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 358:	48b9                	li	a7,14
 ecall
 35a:	00000073          	ecall
 ret
 35e:	8082                	ret

0000000000000360 <waitx>:
.global waitx
waitx:
 li a7, SYS_waitx
 360:	48d9                	li	a7,22
 ecall
 362:	00000073          	ecall
 ret
 366:	8082                	ret

0000000000000368 <getreadcount>:
.global getreadcount
getreadcount:
 li a7, SYS_getreadcount
 368:	48dd                	li	a7,23
 ecall
 36a:	00000073          	ecall
 ret
 36e:	8082                	ret

0000000000000370 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 370:	1101                	add	sp,sp,-32
 372:	ec06                	sd	ra,24(sp)
 374:	e822                	sd	s0,16(sp)
 376:	1000                	add	s0,sp,32
 378:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 37c:	4605                	li	a2,1
 37e:	fef40593          	add	a1,s0,-17
 382:	00000097          	auipc	ra,0x0
 386:	f5e080e7          	jalr	-162(ra) # 2e0 <write>
}
 38a:	60e2                	ld	ra,24(sp)
 38c:	6442                	ld	s0,16(sp)
 38e:	6105                	add	sp,sp,32
 390:	8082                	ret

0000000000000392 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 392:	7139                	add	sp,sp,-64
 394:	fc06                	sd	ra,56(sp)
 396:	f822                	sd	s0,48(sp)
 398:	f426                	sd	s1,40(sp)
 39a:	f04a                	sd	s2,32(sp)
 39c:	ec4e                	sd	s3,24(sp)
 39e:	0080                	add	s0,sp,64
 3a0:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 3a2:	c299                	beqz	a3,3a8 <printint+0x16>
 3a4:	0805c963          	bltz	a1,436 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 3a8:	2581                	sext.w	a1,a1
  neg = 0;
 3aa:	4881                	li	a7,0
 3ac:	fc040693          	add	a3,s0,-64
  }

  i = 0;
 3b0:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 3b2:	2601                	sext.w	a2,a2
 3b4:	00000517          	auipc	a0,0x0
 3b8:	49450513          	add	a0,a0,1172 # 848 <digits>
 3bc:	883a                	mv	a6,a4
 3be:	2705                	addw	a4,a4,1
 3c0:	02c5f7bb          	remuw	a5,a1,a2
 3c4:	1782                	sll	a5,a5,0x20
 3c6:	9381                	srl	a5,a5,0x20
 3c8:	97aa                	add	a5,a5,a0
 3ca:	0007c783          	lbu	a5,0(a5)
 3ce:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 3d2:	0005879b          	sext.w	a5,a1
 3d6:	02c5d5bb          	divuw	a1,a1,a2
 3da:	0685                	add	a3,a3,1
 3dc:	fec7f0e3          	bgeu	a5,a2,3bc <printint+0x2a>
  if(neg)
 3e0:	00088c63          	beqz	a7,3f8 <printint+0x66>
    buf[i++] = '-';
 3e4:	fd070793          	add	a5,a4,-48
 3e8:	00878733          	add	a4,a5,s0
 3ec:	02d00793          	li	a5,45
 3f0:	fef70823          	sb	a5,-16(a4)
 3f4:	0028071b          	addw	a4,a6,2

  while(--i >= 0)
 3f8:	02e05863          	blez	a4,428 <printint+0x96>
 3fc:	fc040793          	add	a5,s0,-64
 400:	00e78933          	add	s2,a5,a4
 404:	fff78993          	add	s3,a5,-1
 408:	99ba                	add	s3,s3,a4
 40a:	377d                	addw	a4,a4,-1
 40c:	1702                	sll	a4,a4,0x20
 40e:	9301                	srl	a4,a4,0x20
 410:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 414:	fff94583          	lbu	a1,-1(s2)
 418:	8526                	mv	a0,s1
 41a:	00000097          	auipc	ra,0x0
 41e:	f56080e7          	jalr	-170(ra) # 370 <putc>
  while(--i >= 0)
 422:	197d                	add	s2,s2,-1
 424:	ff3918e3          	bne	s2,s3,414 <printint+0x82>
}
 428:	70e2                	ld	ra,56(sp)
 42a:	7442                	ld	s0,48(sp)
 42c:	74a2                	ld	s1,40(sp)
 42e:	7902                	ld	s2,32(sp)
 430:	69e2                	ld	s3,24(sp)
 432:	6121                	add	sp,sp,64
 434:	8082                	ret
    x = -xx;
 436:	40b005bb          	negw	a1,a1
    neg = 1;
 43a:	4885                	li	a7,1
    x = -xx;
 43c:	bf85                	j	3ac <printint+0x1a>

000000000000043e <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 43e:	715d                	add	sp,sp,-80
 440:	e486                	sd	ra,72(sp)
 442:	e0a2                	sd	s0,64(sp)
 444:	fc26                	sd	s1,56(sp)
 446:	f84a                	sd	s2,48(sp)
 448:	f44e                	sd	s3,40(sp)
 44a:	f052                	sd	s4,32(sp)
 44c:	ec56                	sd	s5,24(sp)
 44e:	e85a                	sd	s6,16(sp)
 450:	e45e                	sd	s7,8(sp)
 452:	e062                	sd	s8,0(sp)
 454:	0880                	add	s0,sp,80
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 456:	0005c903          	lbu	s2,0(a1)
 45a:	18090c63          	beqz	s2,5f2 <vprintf+0x1b4>
 45e:	8aaa                	mv	s5,a0
 460:	8bb2                	mv	s7,a2
 462:	00158493          	add	s1,a1,1
  state = 0;
 466:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 468:	02500a13          	li	s4,37
 46c:	4b55                	li	s6,21
 46e:	a839                	j	48c <vprintf+0x4e>
        putc(fd, c);
 470:	85ca                	mv	a1,s2
 472:	8556                	mv	a0,s5
 474:	00000097          	auipc	ra,0x0
 478:	efc080e7          	jalr	-260(ra) # 370 <putc>
 47c:	a019                	j	482 <vprintf+0x44>
    } else if(state == '%'){
 47e:	01498d63          	beq	s3,s4,498 <vprintf+0x5a>
  for(i = 0; fmt[i]; i++){
 482:	0485                	add	s1,s1,1
 484:	fff4c903          	lbu	s2,-1(s1)
 488:	16090563          	beqz	s2,5f2 <vprintf+0x1b4>
    if(state == 0){
 48c:	fe0999e3          	bnez	s3,47e <vprintf+0x40>
      if(c == '%'){
 490:	ff4910e3          	bne	s2,s4,470 <vprintf+0x32>
        state = '%';
 494:	89d2                	mv	s3,s4
 496:	b7f5                	j	482 <vprintf+0x44>
      if(c == 'd'){
 498:	13490263          	beq	s2,s4,5bc <vprintf+0x17e>
 49c:	f9d9079b          	addw	a5,s2,-99
 4a0:	0ff7f793          	zext.b	a5,a5
 4a4:	12fb6563          	bltu	s6,a5,5ce <vprintf+0x190>
 4a8:	f9d9079b          	addw	a5,s2,-99
 4ac:	0ff7f713          	zext.b	a4,a5
 4b0:	10eb6f63          	bltu	s6,a4,5ce <vprintf+0x190>
 4b4:	00271793          	sll	a5,a4,0x2
 4b8:	00000717          	auipc	a4,0x0
 4bc:	33870713          	add	a4,a4,824 # 7f0 <malloc+0x100>
 4c0:	97ba                	add	a5,a5,a4
 4c2:	439c                	lw	a5,0(a5)
 4c4:	97ba                	add	a5,a5,a4
 4c6:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 4c8:	008b8913          	add	s2,s7,8
 4cc:	4685                	li	a3,1
 4ce:	4629                	li	a2,10
 4d0:	000ba583          	lw	a1,0(s7)
 4d4:	8556                	mv	a0,s5
 4d6:	00000097          	auipc	ra,0x0
 4da:	ebc080e7          	jalr	-324(ra) # 392 <printint>
 4de:	8bca                	mv	s7,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 4e0:	4981                	li	s3,0
 4e2:	b745                	j	482 <vprintf+0x44>
        printint(fd, va_arg(ap, uint64), 10, 0);
 4e4:	008b8913          	add	s2,s7,8
 4e8:	4681                	li	a3,0
 4ea:	4629                	li	a2,10
 4ec:	000ba583          	lw	a1,0(s7)
 4f0:	8556                	mv	a0,s5
 4f2:	00000097          	auipc	ra,0x0
 4f6:	ea0080e7          	jalr	-352(ra) # 392 <printint>
 4fa:	8bca                	mv	s7,s2
      state = 0;
 4fc:	4981                	li	s3,0
 4fe:	b751                	j	482 <vprintf+0x44>
        printint(fd, va_arg(ap, int), 16, 0);
 500:	008b8913          	add	s2,s7,8
 504:	4681                	li	a3,0
 506:	4641                	li	a2,16
 508:	000ba583          	lw	a1,0(s7)
 50c:	8556                	mv	a0,s5
 50e:	00000097          	auipc	ra,0x0
 512:	e84080e7          	jalr	-380(ra) # 392 <printint>
 516:	8bca                	mv	s7,s2
      state = 0;
 518:	4981                	li	s3,0
 51a:	b7a5                	j	482 <vprintf+0x44>
        printptr(fd, va_arg(ap, uint64));
 51c:	008b8c13          	add	s8,s7,8
 520:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 524:	03000593          	li	a1,48
 528:	8556                	mv	a0,s5
 52a:	00000097          	auipc	ra,0x0
 52e:	e46080e7          	jalr	-442(ra) # 370 <putc>
  putc(fd, 'x');
 532:	07800593          	li	a1,120
 536:	8556                	mv	a0,s5
 538:	00000097          	auipc	ra,0x0
 53c:	e38080e7          	jalr	-456(ra) # 370 <putc>
 540:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 542:	00000b97          	auipc	s7,0x0
 546:	306b8b93          	add	s7,s7,774 # 848 <digits>
 54a:	03c9d793          	srl	a5,s3,0x3c
 54e:	97de                	add	a5,a5,s7
 550:	0007c583          	lbu	a1,0(a5)
 554:	8556                	mv	a0,s5
 556:	00000097          	auipc	ra,0x0
 55a:	e1a080e7          	jalr	-486(ra) # 370 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 55e:	0992                	sll	s3,s3,0x4
 560:	397d                	addw	s2,s2,-1
 562:	fe0914e3          	bnez	s2,54a <vprintf+0x10c>
        printptr(fd, va_arg(ap, uint64));
 566:	8be2                	mv	s7,s8
      state = 0;
 568:	4981                	li	s3,0
 56a:	bf21                	j	482 <vprintf+0x44>
        s = va_arg(ap, char*);
 56c:	008b8993          	add	s3,s7,8
 570:	000bb903          	ld	s2,0(s7)
        if(s == 0)
 574:	02090163          	beqz	s2,596 <vprintf+0x158>
        while(*s != 0){
 578:	00094583          	lbu	a1,0(s2)
 57c:	c9a5                	beqz	a1,5ec <vprintf+0x1ae>
          putc(fd, *s);
 57e:	8556                	mv	a0,s5
 580:	00000097          	auipc	ra,0x0
 584:	df0080e7          	jalr	-528(ra) # 370 <putc>
          s++;
 588:	0905                	add	s2,s2,1
        while(*s != 0){
 58a:	00094583          	lbu	a1,0(s2)
 58e:	f9e5                	bnez	a1,57e <vprintf+0x140>
        s = va_arg(ap, char*);
 590:	8bce                	mv	s7,s3
      state = 0;
 592:	4981                	li	s3,0
 594:	b5fd                	j	482 <vprintf+0x44>
          s = "(null)";
 596:	00000917          	auipc	s2,0x0
 59a:	25290913          	add	s2,s2,594 # 7e8 <malloc+0xf8>
        while(*s != 0){
 59e:	02800593          	li	a1,40
 5a2:	bff1                	j	57e <vprintf+0x140>
        putc(fd, va_arg(ap, uint));
 5a4:	008b8913          	add	s2,s7,8
 5a8:	000bc583          	lbu	a1,0(s7)
 5ac:	8556                	mv	a0,s5
 5ae:	00000097          	auipc	ra,0x0
 5b2:	dc2080e7          	jalr	-574(ra) # 370 <putc>
 5b6:	8bca                	mv	s7,s2
      state = 0;
 5b8:	4981                	li	s3,0
 5ba:	b5e1                	j	482 <vprintf+0x44>
        putc(fd, c);
 5bc:	02500593          	li	a1,37
 5c0:	8556                	mv	a0,s5
 5c2:	00000097          	auipc	ra,0x0
 5c6:	dae080e7          	jalr	-594(ra) # 370 <putc>
      state = 0;
 5ca:	4981                	li	s3,0
 5cc:	bd5d                	j	482 <vprintf+0x44>
        putc(fd, '%');
 5ce:	02500593          	li	a1,37
 5d2:	8556                	mv	a0,s5
 5d4:	00000097          	auipc	ra,0x0
 5d8:	d9c080e7          	jalr	-612(ra) # 370 <putc>
        putc(fd, c);
 5dc:	85ca                	mv	a1,s2
 5de:	8556                	mv	a0,s5
 5e0:	00000097          	auipc	ra,0x0
 5e4:	d90080e7          	jalr	-624(ra) # 370 <putc>
      state = 0;
 5e8:	4981                	li	s3,0
 5ea:	bd61                	j	482 <vprintf+0x44>
        s = va_arg(ap, char*);
 5ec:	8bce                	mv	s7,s3
      state = 0;
 5ee:	4981                	li	s3,0
 5f0:	bd49                	j	482 <vprintf+0x44>
    }
  }
}
 5f2:	60a6                	ld	ra,72(sp)
 5f4:	6406                	ld	s0,64(sp)
 5f6:	74e2                	ld	s1,56(sp)
 5f8:	7942                	ld	s2,48(sp)
 5fa:	79a2                	ld	s3,40(sp)
 5fc:	7a02                	ld	s4,32(sp)
 5fe:	6ae2                	ld	s5,24(sp)
 600:	6b42                	ld	s6,16(sp)
 602:	6ba2                	ld	s7,8(sp)
 604:	6c02                	ld	s8,0(sp)
 606:	6161                	add	sp,sp,80
 608:	8082                	ret

000000000000060a <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 60a:	715d                	add	sp,sp,-80
 60c:	ec06                	sd	ra,24(sp)
 60e:	e822                	sd	s0,16(sp)
 610:	1000                	add	s0,sp,32
 612:	e010                	sd	a2,0(s0)
 614:	e414                	sd	a3,8(s0)
 616:	e818                	sd	a4,16(s0)
 618:	ec1c                	sd	a5,24(s0)
 61a:	03043023          	sd	a6,32(s0)
 61e:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 622:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 626:	8622                	mv	a2,s0
 628:	00000097          	auipc	ra,0x0
 62c:	e16080e7          	jalr	-490(ra) # 43e <vprintf>
}
 630:	60e2                	ld	ra,24(sp)
 632:	6442                	ld	s0,16(sp)
 634:	6161                	add	sp,sp,80
 636:	8082                	ret

0000000000000638 <printf>:

void
printf(const char *fmt, ...)
{
 638:	711d                	add	sp,sp,-96
 63a:	ec06                	sd	ra,24(sp)
 63c:	e822                	sd	s0,16(sp)
 63e:	1000                	add	s0,sp,32
 640:	e40c                	sd	a1,8(s0)
 642:	e810                	sd	a2,16(s0)
 644:	ec14                	sd	a3,24(s0)
 646:	f018                	sd	a4,32(s0)
 648:	f41c                	sd	a5,40(s0)
 64a:	03043823          	sd	a6,48(s0)
 64e:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 652:	00840613          	add	a2,s0,8
 656:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 65a:	85aa                	mv	a1,a0
 65c:	4505                	li	a0,1
 65e:	00000097          	auipc	ra,0x0
 662:	de0080e7          	jalr	-544(ra) # 43e <vprintf>
}
 666:	60e2                	ld	ra,24(sp)
 668:	6442                	ld	s0,16(sp)
 66a:	6125                	add	sp,sp,96
 66c:	8082                	ret

000000000000066e <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 66e:	1141                	add	sp,sp,-16
 670:	e422                	sd	s0,8(sp)
 672:	0800                	add	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 674:	ff050693          	add	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 678:	00001797          	auipc	a5,0x1
 67c:	9887b783          	ld	a5,-1656(a5) # 1000 <freep>
 680:	a02d                	j	6aa <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 682:	4618                	lw	a4,8(a2)
 684:	9f2d                	addw	a4,a4,a1
 686:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 68a:	6398                	ld	a4,0(a5)
 68c:	6310                	ld	a2,0(a4)
 68e:	a83d                	j	6cc <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 690:	ff852703          	lw	a4,-8(a0)
 694:	9f31                	addw	a4,a4,a2
 696:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 698:	ff053683          	ld	a3,-16(a0)
 69c:	a091                	j	6e0 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 69e:	6398                	ld	a4,0(a5)
 6a0:	00e7e463          	bltu	a5,a4,6a8 <free+0x3a>
 6a4:	00e6ea63          	bltu	a3,a4,6b8 <free+0x4a>
{
 6a8:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6aa:	fed7fae3          	bgeu	a5,a3,69e <free+0x30>
 6ae:	6398                	ld	a4,0(a5)
 6b0:	00e6e463          	bltu	a3,a4,6b8 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6b4:	fee7eae3          	bltu	a5,a4,6a8 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 6b8:	ff852583          	lw	a1,-8(a0)
 6bc:	6390                	ld	a2,0(a5)
 6be:	02059813          	sll	a6,a1,0x20
 6c2:	01c85713          	srl	a4,a6,0x1c
 6c6:	9736                	add	a4,a4,a3
 6c8:	fae60de3          	beq	a2,a4,682 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 6cc:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 6d0:	4790                	lw	a2,8(a5)
 6d2:	02061593          	sll	a1,a2,0x20
 6d6:	01c5d713          	srl	a4,a1,0x1c
 6da:	973e                	add	a4,a4,a5
 6dc:	fae68ae3          	beq	a3,a4,690 <free+0x22>
    p->s.ptr = bp->s.ptr;
 6e0:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 6e2:	00001717          	auipc	a4,0x1
 6e6:	90f73f23          	sd	a5,-1762(a4) # 1000 <freep>
}
 6ea:	6422                	ld	s0,8(sp)
 6ec:	0141                	add	sp,sp,16
 6ee:	8082                	ret

00000000000006f0 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 6f0:	7139                	add	sp,sp,-64
 6f2:	fc06                	sd	ra,56(sp)
 6f4:	f822                	sd	s0,48(sp)
 6f6:	f426                	sd	s1,40(sp)
 6f8:	f04a                	sd	s2,32(sp)
 6fa:	ec4e                	sd	s3,24(sp)
 6fc:	e852                	sd	s4,16(sp)
 6fe:	e456                	sd	s5,8(sp)
 700:	e05a                	sd	s6,0(sp)
 702:	0080                	add	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 704:	02051493          	sll	s1,a0,0x20
 708:	9081                	srl	s1,s1,0x20
 70a:	04bd                	add	s1,s1,15
 70c:	8091                	srl	s1,s1,0x4
 70e:	0014899b          	addw	s3,s1,1
 712:	0485                	add	s1,s1,1
  if((prevp = freep) == 0){
 714:	00001517          	auipc	a0,0x1
 718:	8ec53503          	ld	a0,-1812(a0) # 1000 <freep>
 71c:	c515                	beqz	a0,748 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 71e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 720:	4798                	lw	a4,8(a5)
 722:	02977f63          	bgeu	a4,s1,760 <malloc+0x70>
  if(nu < 4096)
 726:	8a4e                	mv	s4,s3
 728:	0009871b          	sext.w	a4,s3
 72c:	6685                	lui	a3,0x1
 72e:	00d77363          	bgeu	a4,a3,734 <malloc+0x44>
 732:	6a05                	lui	s4,0x1
 734:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 738:	004a1a1b          	sllw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 73c:	00001917          	auipc	s2,0x1
 740:	8c490913          	add	s2,s2,-1852 # 1000 <freep>
  if(p == (char*)-1)
 744:	5afd                	li	s5,-1
 746:	a895                	j	7ba <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 748:	00001797          	auipc	a5,0x1
 74c:	8c878793          	add	a5,a5,-1848 # 1010 <base>
 750:	00001717          	auipc	a4,0x1
 754:	8af73823          	sd	a5,-1872(a4) # 1000 <freep>
 758:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 75a:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 75e:	b7e1                	j	726 <malloc+0x36>
      if(p->s.size == nunits)
 760:	02e48c63          	beq	s1,a4,798 <malloc+0xa8>
        p->s.size -= nunits;
 764:	4137073b          	subw	a4,a4,s3
 768:	c798                	sw	a4,8(a5)
        p += p->s.size;
 76a:	02071693          	sll	a3,a4,0x20
 76e:	01c6d713          	srl	a4,a3,0x1c
 772:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 774:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 778:	00001717          	auipc	a4,0x1
 77c:	88a73423          	sd	a0,-1912(a4) # 1000 <freep>
      return (void*)(p + 1);
 780:	01078513          	add	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 784:	70e2                	ld	ra,56(sp)
 786:	7442                	ld	s0,48(sp)
 788:	74a2                	ld	s1,40(sp)
 78a:	7902                	ld	s2,32(sp)
 78c:	69e2                	ld	s3,24(sp)
 78e:	6a42                	ld	s4,16(sp)
 790:	6aa2                	ld	s5,8(sp)
 792:	6b02                	ld	s6,0(sp)
 794:	6121                	add	sp,sp,64
 796:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 798:	6398                	ld	a4,0(a5)
 79a:	e118                	sd	a4,0(a0)
 79c:	bff1                	j	778 <malloc+0x88>
  hp->s.size = nu;
 79e:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 7a2:	0541                	add	a0,a0,16
 7a4:	00000097          	auipc	ra,0x0
 7a8:	eca080e7          	jalr	-310(ra) # 66e <free>
  return freep;
 7ac:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 7b0:	d971                	beqz	a0,784 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7b2:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7b4:	4798                	lw	a4,8(a5)
 7b6:	fa9775e3          	bgeu	a4,s1,760 <malloc+0x70>
    if(p == freep)
 7ba:	00093703          	ld	a4,0(s2)
 7be:	853e                	mv	a0,a5
 7c0:	fef719e3          	bne	a4,a5,7b2 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 7c4:	8552                	mv	a0,s4
 7c6:	00000097          	auipc	ra,0x0
 7ca:	b82080e7          	jalr	-1150(ra) # 348 <sbrk>
  if(p == (char*)-1)
 7ce:	fd5518e3          	bne	a0,s5,79e <malloc+0xae>
        return 0;
 7d2:	4501                	li	a0,0
 7d4:	bf45                	j	784 <malloc+0x94>
