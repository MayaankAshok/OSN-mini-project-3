
user/_test_1:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <simpletest>:
// allocate more than half of physical memory,
// then fork. this will fail in the default
// kernel, which does not support copy-on-write.
void
simpletest()
{
   0:	7179                	add	sp,sp,-48
   2:	f406                	sd	ra,40(sp)
   4:	f022                	sd	s0,32(sp)
   6:	ec26                	sd	s1,24(sp)
   8:	e84a                	sd	s2,16(sp)
   a:	e44e                	sd	s3,8(sp)
   c:	1800                	add	s0,sp,48
  uint64 phys_size = PHYSTOP - KERNBASE;
  int sz = (phys_size / 3) * 2;

  printf("simple: ");
   e:	00001517          	auipc	a0,0x1
  12:	c6250513          	add	a0,a0,-926 # c70 <malloc+0xe6>
  16:	00001097          	auipc	ra,0x1
  1a:	abc080e7          	jalr	-1348(ra) # ad2 <printf>
  
  char *p = sbrk(sz);
  1e:	05555537          	lui	a0,0x5555
  22:	55450513          	add	a0,a0,1364 # 5555554 <base+0x5550544>
  26:	00000097          	auipc	ra,0x0
  2a:	7bc080e7          	jalr	1980(ra) # 7e2 <sbrk>
  if(p == (char*)0xffffffffffffffffL){
  2e:	57fd                	li	a5,-1
  30:	06f50563          	beq	a0,a5,9a <simpletest+0x9a>
  34:	84aa                	mv	s1,a0
    printf("sbrk(%d) failed\n", sz);
    exit(-1);
  }

  for(char *q = p; q < p + sz; q += 4096){
  36:	05556937          	lui	s2,0x5556
  3a:	992a                	add	s2,s2,a0
  3c:	6985                	lui	s3,0x1
    *(int*)q = getpid();
  3e:	00000097          	auipc	ra,0x0
  42:	79c080e7          	jalr	1948(ra) # 7da <getpid>
  46:	c088                	sw	a0,0(s1)
  for(char *q = p; q < p + sz; q += 4096){
  48:	94ce                	add	s1,s1,s3
  4a:	fe991ae3          	bne	s2,s1,3e <simpletest+0x3e>
  }

  int pid = fork();
  4e:	00000097          	auipc	ra,0x0
  52:	704080e7          	jalr	1796(ra) # 752 <fork>
  if(pid < 0){
  56:	06054363          	bltz	a0,bc <simpletest+0xbc>
    printf("fork() failed\n");
    exit(-1);
  }

  if(pid == 0)
  5a:	cd35                	beqz	a0,d6 <simpletest+0xd6>
    exit(0);

  wait(0);
  5c:	4501                	li	a0,0
  5e:	00000097          	auipc	ra,0x0
  62:	704080e7          	jalr	1796(ra) # 762 <wait>

  if(sbrk(-sz) == (char*)0xffffffffffffffffL){
  66:	faaab537          	lui	a0,0xfaaab
  6a:	aac50513          	add	a0,a0,-1364 # fffffffffaaaaaac <base+0xfffffffffaaa5a9c>
  6e:	00000097          	auipc	ra,0x0
  72:	774080e7          	jalr	1908(ra) # 7e2 <sbrk>
  76:	57fd                	li	a5,-1
  78:	06f50363          	beq	a0,a5,de <simpletest+0xde>
    printf("sbrk(-%d) failed\n", sz);
    exit(-1);
  }

  printf("ok\n");
  7c:	00001517          	auipc	a0,0x1
  80:	c4450513          	add	a0,a0,-956 # cc0 <malloc+0x136>
  84:	00001097          	auipc	ra,0x1
  88:	a4e080e7          	jalr	-1458(ra) # ad2 <printf>
}
  8c:	70a2                	ld	ra,40(sp)
  8e:	7402                	ld	s0,32(sp)
  90:	64e2                	ld	s1,24(sp)
  92:	6942                	ld	s2,16(sp)
  94:	69a2                	ld	s3,8(sp)
  96:	6145                	add	sp,sp,48
  98:	8082                	ret
    printf("sbrk(%d) failed\n", sz);
  9a:	055555b7          	lui	a1,0x5555
  9e:	55458593          	add	a1,a1,1364 # 5555554 <base+0x5550544>
  a2:	00001517          	auipc	a0,0x1
  a6:	bde50513          	add	a0,a0,-1058 # c80 <malloc+0xf6>
  aa:	00001097          	auipc	ra,0x1
  ae:	a28080e7          	jalr	-1496(ra) # ad2 <printf>
    exit(-1);
  b2:	557d                	li	a0,-1
  b4:	00000097          	auipc	ra,0x0
  b8:	6a6080e7          	jalr	1702(ra) # 75a <exit>
    printf("fork() failed\n");
  bc:	00001517          	auipc	a0,0x1
  c0:	bdc50513          	add	a0,a0,-1060 # c98 <malloc+0x10e>
  c4:	00001097          	auipc	ra,0x1
  c8:	a0e080e7          	jalr	-1522(ra) # ad2 <printf>
    exit(-1);
  cc:	557d                	li	a0,-1
  ce:	00000097          	auipc	ra,0x0
  d2:	68c080e7          	jalr	1676(ra) # 75a <exit>
    exit(0);
  d6:	00000097          	auipc	ra,0x0
  da:	684080e7          	jalr	1668(ra) # 75a <exit>
    printf("sbrk(-%d) failed\n", sz);
  de:	055555b7          	lui	a1,0x5555
  e2:	55458593          	add	a1,a1,1364 # 5555554 <base+0x5550544>
  e6:	00001517          	auipc	a0,0x1
  ea:	bc250513          	add	a0,a0,-1086 # ca8 <malloc+0x11e>
  ee:	00001097          	auipc	ra,0x1
  f2:	9e4080e7          	jalr	-1564(ra) # ad2 <printf>
    exit(-1);
  f6:	557d                	li	a0,-1
  f8:	00000097          	auipc	ra,0x0
  fc:	662080e7          	jalr	1634(ra) # 75a <exit>

0000000000000100 <threetest>:
// this causes more than half of physical memory
// to be allocated, so it also checks whether
// copied pages are freed.
void
threetest()
{
 100:	7179                	add	sp,sp,-48
 102:	f406                	sd	ra,40(sp)
 104:	f022                	sd	s0,32(sp)
 106:	ec26                	sd	s1,24(sp)
 108:	e84a                	sd	s2,16(sp)
 10a:	e44e                	sd	s3,8(sp)
 10c:	e052                	sd	s4,0(sp)
 10e:	1800                	add	s0,sp,48
  uint64 phys_size = PHYSTOP - KERNBASE;
  int sz = phys_size / 4;
  int pid1, pid2;

  printf("three: ");
 110:	00001517          	auipc	a0,0x1
 114:	bb850513          	add	a0,a0,-1096 # cc8 <malloc+0x13e>
 118:	00001097          	auipc	ra,0x1
 11c:	9ba080e7          	jalr	-1606(ra) # ad2 <printf>
  
  char *p = sbrk(sz);
 120:	02000537          	lui	a0,0x2000
 124:	00000097          	auipc	ra,0x0
 128:	6be080e7          	jalr	1726(ra) # 7e2 <sbrk>
  if(p == (char*)0xffffffffffffffffL){
 12c:	57fd                	li	a5,-1
 12e:	08f50763          	beq	a0,a5,1bc <threetest+0xbc>
 132:	84aa                	mv	s1,a0
    printf("sbrk(%d) failed\n", sz);
    exit(-1);
  }

  pid1 = fork();
 134:	00000097          	auipc	ra,0x0
 138:	61e080e7          	jalr	1566(ra) # 752 <fork>
  if(pid1 < 0){
 13c:	08054f63          	bltz	a0,1da <threetest+0xda>
    printf("fork failed\n");
    exit(-1);
  }
  if(pid1 == 0){
 140:	c955                	beqz	a0,1f4 <threetest+0xf4>
      *(int*)q = 9999;
    }
    exit(0);
  }

  for(char *q = p; q < p + sz; q += 4096){
 142:	020009b7          	lui	s3,0x2000
 146:	99a6                	add	s3,s3,s1
 148:	8926                	mv	s2,s1
 14a:	6a05                	lui	s4,0x1
    *(int*)q = getpid();
 14c:	00000097          	auipc	ra,0x0
 150:	68e080e7          	jalr	1678(ra) # 7da <getpid>
 154:	00a92023          	sw	a0,0(s2) # 5556000 <base+0x5550ff0>
  for(char *q = p; q < p + sz; q += 4096){
 158:	9952                	add	s2,s2,s4
 15a:	ff3919e3          	bne	s2,s3,14c <threetest+0x4c>
  }

  wait(0);
 15e:	4501                	li	a0,0
 160:	00000097          	auipc	ra,0x0
 164:	602080e7          	jalr	1538(ra) # 762 <wait>

  sleep(1);
 168:	4505                	li	a0,1
 16a:	00000097          	auipc	ra,0x0
 16e:	680080e7          	jalr	1664(ra) # 7ea <sleep>

  for(char *q = p; q < p + sz; q += 4096){
 172:	6a05                	lui	s4,0x1
    if(*(int*)q != getpid()){
 174:	0004a903          	lw	s2,0(s1)
 178:	00000097          	auipc	ra,0x0
 17c:	662080e7          	jalr	1634(ra) # 7da <getpid>
 180:	10a91a63          	bne	s2,a0,294 <threetest+0x194>
  for(char *q = p; q < p + sz; q += 4096){
 184:	94d2                	add	s1,s1,s4
 186:	ff3497e3          	bne	s1,s3,174 <threetest+0x74>
      printf("wrong content\n");
      exit(-1);
    }
  }

  if(sbrk(-sz) == (char*)0xffffffffffffffffL){
 18a:	fe000537          	lui	a0,0xfe000
 18e:	00000097          	auipc	ra,0x0
 192:	654080e7          	jalr	1620(ra) # 7e2 <sbrk>
 196:	57fd                	li	a5,-1
 198:	10f50b63          	beq	a0,a5,2ae <threetest+0x1ae>
    printf("sbrk(-%d) failed\n", sz);
    exit(-1);
  }

  printf("ok\n");
 19c:	00001517          	auipc	a0,0x1
 1a0:	b2450513          	add	a0,a0,-1244 # cc0 <malloc+0x136>
 1a4:	00001097          	auipc	ra,0x1
 1a8:	92e080e7          	jalr	-1746(ra) # ad2 <printf>
}
 1ac:	70a2                	ld	ra,40(sp)
 1ae:	7402                	ld	s0,32(sp)
 1b0:	64e2                	ld	s1,24(sp)
 1b2:	6942                	ld	s2,16(sp)
 1b4:	69a2                	ld	s3,8(sp)
 1b6:	6a02                	ld	s4,0(sp)
 1b8:	6145                	add	sp,sp,48
 1ba:	8082                	ret
    printf("sbrk(%d) failed\n", sz);
 1bc:	020005b7          	lui	a1,0x2000
 1c0:	00001517          	auipc	a0,0x1
 1c4:	ac050513          	add	a0,a0,-1344 # c80 <malloc+0xf6>
 1c8:	00001097          	auipc	ra,0x1
 1cc:	90a080e7          	jalr	-1782(ra) # ad2 <printf>
    exit(-1);
 1d0:	557d                	li	a0,-1
 1d2:	00000097          	auipc	ra,0x0
 1d6:	588080e7          	jalr	1416(ra) # 75a <exit>
    printf("fork failed\n");
 1da:	00001517          	auipc	a0,0x1
 1de:	af650513          	add	a0,a0,-1290 # cd0 <malloc+0x146>
 1e2:	00001097          	auipc	ra,0x1
 1e6:	8f0080e7          	jalr	-1808(ra) # ad2 <printf>
    exit(-1);
 1ea:	557d                	li	a0,-1
 1ec:	00000097          	auipc	ra,0x0
 1f0:	56e080e7          	jalr	1390(ra) # 75a <exit>
    pid2 = fork();
 1f4:	00000097          	auipc	ra,0x0
 1f8:	55e080e7          	jalr	1374(ra) # 752 <fork>
    if(pid2 < 0){
 1fc:	04054263          	bltz	a0,240 <threetest+0x140>
    if(pid2 == 0){
 200:	ed29                	bnez	a0,25a <threetest+0x15a>
      for(char *q = p; q < p + (sz/5)*4; q += 4096){
 202:	0199a9b7          	lui	s3,0x199a
 206:	99a6                	add	s3,s3,s1
 208:	8926                	mv	s2,s1
 20a:	6a05                	lui	s4,0x1
        *(int*)q = getpid();
 20c:	00000097          	auipc	ra,0x0
 210:	5ce080e7          	jalr	1486(ra) # 7da <getpid>
 214:	00a92023          	sw	a0,0(s2)
      for(char *q = p; q < p + (sz/5)*4; q += 4096){
 218:	9952                	add	s2,s2,s4
 21a:	ff2999e3          	bne	s3,s2,20c <threetest+0x10c>
      for(char *q = p; q < p + (sz/5)*4; q += 4096){
 21e:	6a05                	lui	s4,0x1
        if(*(int*)q != getpid()){
 220:	0004a903          	lw	s2,0(s1)
 224:	00000097          	auipc	ra,0x0
 228:	5b6080e7          	jalr	1462(ra) # 7da <getpid>
 22c:	04a91763          	bne	s2,a0,27a <threetest+0x17a>
      for(char *q = p; q < p + (sz/5)*4; q += 4096){
 230:	94d2                	add	s1,s1,s4
 232:	fe9997e3          	bne	s3,s1,220 <threetest+0x120>
      exit(-1);
 236:	557d                	li	a0,-1
 238:	00000097          	auipc	ra,0x0
 23c:	522080e7          	jalr	1314(ra) # 75a <exit>
      printf("fork failed");
 240:	00001517          	auipc	a0,0x1
 244:	aa050513          	add	a0,a0,-1376 # ce0 <malloc+0x156>
 248:	00001097          	auipc	ra,0x1
 24c:	88a080e7          	jalr	-1910(ra) # ad2 <printf>
      exit(-1);
 250:	557d                	li	a0,-1
 252:	00000097          	auipc	ra,0x0
 256:	508080e7          	jalr	1288(ra) # 75a <exit>
    for(char *q = p; q < p + (sz/2); q += 4096){
 25a:	01000737          	lui	a4,0x1000
 25e:	9726                	add	a4,a4,s1
      *(int*)q = 9999;
 260:	6789                	lui	a5,0x2
 262:	70f78793          	add	a5,a5,1807 # 270f <buf+0x6ff>
    for(char *q = p; q < p + (sz/2); q += 4096){
 266:	6685                	lui	a3,0x1
      *(int*)q = 9999;
 268:	c09c                	sw	a5,0(s1)
    for(char *q = p; q < p + (sz/2); q += 4096){
 26a:	94b6                	add	s1,s1,a3
 26c:	fee49ee3          	bne	s1,a4,268 <threetest+0x168>
    exit(0);
 270:	4501                	li	a0,0
 272:	00000097          	auipc	ra,0x0
 276:	4e8080e7          	jalr	1256(ra) # 75a <exit>
          printf("wrong content\n");
 27a:	00001517          	auipc	a0,0x1
 27e:	a7650513          	add	a0,a0,-1418 # cf0 <malloc+0x166>
 282:	00001097          	auipc	ra,0x1
 286:	850080e7          	jalr	-1968(ra) # ad2 <printf>
          exit(-1);
 28a:	557d                	li	a0,-1
 28c:	00000097          	auipc	ra,0x0
 290:	4ce080e7          	jalr	1230(ra) # 75a <exit>
      printf("wrong content\n");
 294:	00001517          	auipc	a0,0x1
 298:	a5c50513          	add	a0,a0,-1444 # cf0 <malloc+0x166>
 29c:	00001097          	auipc	ra,0x1
 2a0:	836080e7          	jalr	-1994(ra) # ad2 <printf>
      exit(-1);
 2a4:	557d                	li	a0,-1
 2a6:	00000097          	auipc	ra,0x0
 2aa:	4b4080e7          	jalr	1204(ra) # 75a <exit>
    printf("sbrk(-%d) failed\n", sz);
 2ae:	020005b7          	lui	a1,0x2000
 2b2:	00001517          	auipc	a0,0x1
 2b6:	9f650513          	add	a0,a0,-1546 # ca8 <malloc+0x11e>
 2ba:	00001097          	auipc	ra,0x1
 2be:	818080e7          	jalr	-2024(ra) # ad2 <printf>
    exit(-1);
 2c2:	557d                	li	a0,-1
 2c4:	00000097          	auipc	ra,0x0
 2c8:	496080e7          	jalr	1174(ra) # 75a <exit>

00000000000002cc <filetest>:
char junk3[4096];

// test whether copyout() simulates COW faults.
void
filetest()
{
 2cc:	7179                	add	sp,sp,-48
 2ce:	f406                	sd	ra,40(sp)
 2d0:	f022                	sd	s0,32(sp)
 2d2:	ec26                	sd	s1,24(sp)
 2d4:	e84a                	sd	s2,16(sp)
 2d6:	1800                	add	s0,sp,48
  printf("file: ");
 2d8:	00001517          	auipc	a0,0x1
 2dc:	a2850513          	add	a0,a0,-1496 # d00 <malloc+0x176>
 2e0:	00000097          	auipc	ra,0x0
 2e4:	7f2080e7          	jalr	2034(ra) # ad2 <printf>
  
  buf[0] = 99;
 2e8:	06300793          	li	a5,99
 2ec:	00002717          	auipc	a4,0x2
 2f0:	d2f70223          	sb	a5,-732(a4) # 2010 <buf>

  for(int i = 0; i < 4; i++){
 2f4:	fc042c23          	sw	zero,-40(s0)
    if(pipe(fds) != 0){
 2f8:	00001497          	auipc	s1,0x1
 2fc:	d0848493          	add	s1,s1,-760 # 1000 <fds>
  for(int i = 0; i < 4; i++){
 300:	490d                	li	s2,3
    if(pipe(fds) != 0){
 302:	8526                	mv	a0,s1
 304:	00000097          	auipc	ra,0x0
 308:	466080e7          	jalr	1126(ra) # 76a <pipe>
 30c:	e149                	bnez	a0,38e <filetest+0xc2>
      printf("pipe() failed\n");
      exit(-1);
    }
    int pid = fork();
 30e:	00000097          	auipc	ra,0x0
 312:	444080e7          	jalr	1092(ra) # 752 <fork>
    if(pid < 0){
 316:	08054963          	bltz	a0,3a8 <filetest+0xdc>
      printf("fork failed\n");
      exit(-1);
    }
    if(pid == 0){
 31a:	c545                	beqz	a0,3c2 <filetest+0xf6>
        printf("error: read the wrong value\n");
        exit(1);
      }
      exit(0);
    }
    if(write(fds[1], &i, sizeof(i)) != sizeof(i)){
 31c:	4611                	li	a2,4
 31e:	fd840593          	add	a1,s0,-40
 322:	40c8                	lw	a0,4(s1)
 324:	00000097          	auipc	ra,0x0
 328:	456080e7          	jalr	1110(ra) # 77a <write>
 32c:	4791                	li	a5,4
 32e:	10f51b63          	bne	a0,a5,444 <filetest+0x178>
  for(int i = 0; i < 4; i++){
 332:	fd842783          	lw	a5,-40(s0)
 336:	2785                	addw	a5,a5,1
 338:	0007871b          	sext.w	a4,a5
 33c:	fcf42c23          	sw	a5,-40(s0)
 340:	fce951e3          	bge	s2,a4,302 <filetest+0x36>
      printf("error: write failed\n");
      exit(-1);
    }
  }

  int xstatus = 0;
 344:	fc042e23          	sw	zero,-36(s0)
 348:	4491                	li	s1,4
  for(int i = 0; i < 4; i++) {
    wait(&xstatus);
 34a:	fdc40513          	add	a0,s0,-36
 34e:	00000097          	auipc	ra,0x0
 352:	414080e7          	jalr	1044(ra) # 762 <wait>
    if(xstatus != 0) {
 356:	fdc42783          	lw	a5,-36(s0)
 35a:	10079263          	bnez	a5,45e <filetest+0x192>
  for(int i = 0; i < 4; i++) {
 35e:	34fd                	addw	s1,s1,-1
 360:	f4ed                	bnez	s1,34a <filetest+0x7e>
      exit(1);
    }
  }

  if(buf[0] != 99){
 362:	00002717          	auipc	a4,0x2
 366:	cae74703          	lbu	a4,-850(a4) # 2010 <buf>
 36a:	06300793          	li	a5,99
 36e:	0ef71d63          	bne	a4,a5,468 <filetest+0x19c>
    printf("error: child overwrote parent\n");
    exit(1);
  }

  printf("ok\n");
 372:	00001517          	auipc	a0,0x1
 376:	94e50513          	add	a0,a0,-1714 # cc0 <malloc+0x136>
 37a:	00000097          	auipc	ra,0x0
 37e:	758080e7          	jalr	1880(ra) # ad2 <printf>
}
 382:	70a2                	ld	ra,40(sp)
 384:	7402                	ld	s0,32(sp)
 386:	64e2                	ld	s1,24(sp)
 388:	6942                	ld	s2,16(sp)
 38a:	6145                	add	sp,sp,48
 38c:	8082                	ret
      printf("pipe() failed\n");
 38e:	00001517          	auipc	a0,0x1
 392:	97a50513          	add	a0,a0,-1670 # d08 <malloc+0x17e>
 396:	00000097          	auipc	ra,0x0
 39a:	73c080e7          	jalr	1852(ra) # ad2 <printf>
      exit(-1);
 39e:	557d                	li	a0,-1
 3a0:	00000097          	auipc	ra,0x0
 3a4:	3ba080e7          	jalr	954(ra) # 75a <exit>
      printf("fork failed\n");
 3a8:	00001517          	auipc	a0,0x1
 3ac:	92850513          	add	a0,a0,-1752 # cd0 <malloc+0x146>
 3b0:	00000097          	auipc	ra,0x0
 3b4:	722080e7          	jalr	1826(ra) # ad2 <printf>
      exit(-1);
 3b8:	557d                	li	a0,-1
 3ba:	00000097          	auipc	ra,0x0
 3be:	3a0080e7          	jalr	928(ra) # 75a <exit>
      sleep(1);
 3c2:	4505                	li	a0,1
 3c4:	00000097          	auipc	ra,0x0
 3c8:	426080e7          	jalr	1062(ra) # 7ea <sleep>
      if(read(fds[0], buf, sizeof(i)) != sizeof(i)){
 3cc:	4611                	li	a2,4
 3ce:	00002597          	auipc	a1,0x2
 3d2:	c4258593          	add	a1,a1,-958 # 2010 <buf>
 3d6:	00001517          	auipc	a0,0x1
 3da:	c2a52503          	lw	a0,-982(a0) # 1000 <fds>
 3de:	00000097          	auipc	ra,0x0
 3e2:	394080e7          	jalr	916(ra) # 772 <read>
 3e6:	4791                	li	a5,4
 3e8:	02f51c63          	bne	a0,a5,420 <filetest+0x154>
      sleep(1);
 3ec:	4505                	li	a0,1
 3ee:	00000097          	auipc	ra,0x0
 3f2:	3fc080e7          	jalr	1020(ra) # 7ea <sleep>
      if(j != i){
 3f6:	fd842703          	lw	a4,-40(s0)
 3fa:	00002797          	auipc	a5,0x2
 3fe:	c167a783          	lw	a5,-1002(a5) # 2010 <buf>
 402:	02f70c63          	beq	a4,a5,43a <filetest+0x16e>
        printf("error: read the wrong value\n");
 406:	00001517          	auipc	a0,0x1
 40a:	92a50513          	add	a0,a0,-1750 # d30 <malloc+0x1a6>
 40e:	00000097          	auipc	ra,0x0
 412:	6c4080e7          	jalr	1732(ra) # ad2 <printf>
        exit(1);
 416:	4505                	li	a0,1
 418:	00000097          	auipc	ra,0x0
 41c:	342080e7          	jalr	834(ra) # 75a <exit>
        printf("error: read failed\n");
 420:	00001517          	auipc	a0,0x1
 424:	8f850513          	add	a0,a0,-1800 # d18 <malloc+0x18e>
 428:	00000097          	auipc	ra,0x0
 42c:	6aa080e7          	jalr	1706(ra) # ad2 <printf>
        exit(1);
 430:	4505                	li	a0,1
 432:	00000097          	auipc	ra,0x0
 436:	328080e7          	jalr	808(ra) # 75a <exit>
      exit(0);
 43a:	4501                	li	a0,0
 43c:	00000097          	auipc	ra,0x0
 440:	31e080e7          	jalr	798(ra) # 75a <exit>
      printf("error: write failed\n");
 444:	00001517          	auipc	a0,0x1
 448:	90c50513          	add	a0,a0,-1780 # d50 <malloc+0x1c6>
 44c:	00000097          	auipc	ra,0x0
 450:	686080e7          	jalr	1670(ra) # ad2 <printf>
      exit(-1);
 454:	557d                	li	a0,-1
 456:	00000097          	auipc	ra,0x0
 45a:	304080e7          	jalr	772(ra) # 75a <exit>
      exit(1);
 45e:	4505                	li	a0,1
 460:	00000097          	auipc	ra,0x0
 464:	2fa080e7          	jalr	762(ra) # 75a <exit>
    printf("error: child overwrote parent\n");
 468:	00001517          	auipc	a0,0x1
 46c:	90050513          	add	a0,a0,-1792 # d68 <malloc+0x1de>
 470:	00000097          	auipc	ra,0x0
 474:	662080e7          	jalr	1634(ra) # ad2 <printf>
    exit(1);
 478:	4505                	li	a0,1
 47a:	00000097          	auipc	ra,0x0
 47e:	2e0080e7          	jalr	736(ra) # 75a <exit>

0000000000000482 <main>:

int
main(int argc, char *argv[])
{
 482:	1141                	add	sp,sp,-16
 484:	e406                	sd	ra,8(sp)
 486:	e022                	sd	s0,0(sp)
 488:	0800                	add	s0,sp,16
  simpletest();
 48a:	00000097          	auipc	ra,0x0
 48e:	b76080e7          	jalr	-1162(ra) # 0 <simpletest>

  // check that the first simpletest() freed the physical memory.
  simpletest();
 492:	00000097          	auipc	ra,0x0
 496:	b6e080e7          	jalr	-1170(ra) # 0 <simpletest>

  threetest();
 49a:	00000097          	auipc	ra,0x0
 49e:	c66080e7          	jalr	-922(ra) # 100 <threetest>
  threetest();
 4a2:	00000097          	auipc	ra,0x0
 4a6:	c5e080e7          	jalr	-930(ra) # 100 <threetest>
  threetest();
 4aa:	00000097          	auipc	ra,0x0
 4ae:	c56080e7          	jalr	-938(ra) # 100 <threetest>

  filetest();
 4b2:	00000097          	auipc	ra,0x0
 4b6:	e1a080e7          	jalr	-486(ra) # 2cc <filetest>

  printf("ALL COW TESTS PASSED\n");
 4ba:	00001517          	auipc	a0,0x1
 4be:	8ce50513          	add	a0,a0,-1842 # d88 <malloc+0x1fe>
 4c2:	00000097          	auipc	ra,0x0
 4c6:	610080e7          	jalr	1552(ra) # ad2 <printf>

  exit(0);
 4ca:	4501                	li	a0,0
 4cc:	00000097          	auipc	ra,0x0
 4d0:	28e080e7          	jalr	654(ra) # 75a <exit>

00000000000004d4 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
 4d4:	1141                	add	sp,sp,-16
 4d6:	e406                	sd	ra,8(sp)
 4d8:	e022                	sd	s0,0(sp)
 4da:	0800                	add	s0,sp,16
  extern int main();
  main();
 4dc:	00000097          	auipc	ra,0x0
 4e0:	fa6080e7          	jalr	-90(ra) # 482 <main>
  exit(0);
 4e4:	4501                	li	a0,0
 4e6:	00000097          	auipc	ra,0x0
 4ea:	274080e7          	jalr	628(ra) # 75a <exit>

00000000000004ee <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 4ee:	1141                	add	sp,sp,-16
 4f0:	e422                	sd	s0,8(sp)
 4f2:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 4f4:	87aa                	mv	a5,a0
 4f6:	0585                	add	a1,a1,1
 4f8:	0785                	add	a5,a5,1
 4fa:	fff5c703          	lbu	a4,-1(a1)
 4fe:	fee78fa3          	sb	a4,-1(a5)
 502:	fb75                	bnez	a4,4f6 <strcpy+0x8>
    ;
  return os;
}
 504:	6422                	ld	s0,8(sp)
 506:	0141                	add	sp,sp,16
 508:	8082                	ret

000000000000050a <strcmp>:

int
strcmp(const char *p, const char *q)
{
 50a:	1141                	add	sp,sp,-16
 50c:	e422                	sd	s0,8(sp)
 50e:	0800                	add	s0,sp,16
  while(*p && *p == *q)
 510:	00054783          	lbu	a5,0(a0)
 514:	cb91                	beqz	a5,528 <strcmp+0x1e>
 516:	0005c703          	lbu	a4,0(a1)
 51a:	00f71763          	bne	a4,a5,528 <strcmp+0x1e>
    p++, q++;
 51e:	0505                	add	a0,a0,1
 520:	0585                	add	a1,a1,1
  while(*p && *p == *q)
 522:	00054783          	lbu	a5,0(a0)
 526:	fbe5                	bnez	a5,516 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 528:	0005c503          	lbu	a0,0(a1)
}
 52c:	40a7853b          	subw	a0,a5,a0
 530:	6422                	ld	s0,8(sp)
 532:	0141                	add	sp,sp,16
 534:	8082                	ret

0000000000000536 <strlen>:

uint
strlen(const char *s)
{
 536:	1141                	add	sp,sp,-16
 538:	e422                	sd	s0,8(sp)
 53a:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 53c:	00054783          	lbu	a5,0(a0)
 540:	cf91                	beqz	a5,55c <strlen+0x26>
 542:	0505                	add	a0,a0,1
 544:	87aa                	mv	a5,a0
 546:	86be                	mv	a3,a5
 548:	0785                	add	a5,a5,1
 54a:	fff7c703          	lbu	a4,-1(a5)
 54e:	ff65                	bnez	a4,546 <strlen+0x10>
 550:	40a6853b          	subw	a0,a3,a0
 554:	2505                	addw	a0,a0,1
    ;
  return n;
}
 556:	6422                	ld	s0,8(sp)
 558:	0141                	add	sp,sp,16
 55a:	8082                	ret
  for(n = 0; s[n]; n++)
 55c:	4501                	li	a0,0
 55e:	bfe5                	j	556 <strlen+0x20>

0000000000000560 <memset>:

void*
memset(void *dst, int c, uint n)
{
 560:	1141                	add	sp,sp,-16
 562:	e422                	sd	s0,8(sp)
 564:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 566:	ca19                	beqz	a2,57c <memset+0x1c>
 568:	87aa                	mv	a5,a0
 56a:	1602                	sll	a2,a2,0x20
 56c:	9201                	srl	a2,a2,0x20
 56e:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 572:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 576:	0785                	add	a5,a5,1
 578:	fee79de3          	bne	a5,a4,572 <memset+0x12>
  }
  return dst;
}
 57c:	6422                	ld	s0,8(sp)
 57e:	0141                	add	sp,sp,16
 580:	8082                	ret

0000000000000582 <strchr>:

char*
strchr(const char *s, char c)
{
 582:	1141                	add	sp,sp,-16
 584:	e422                	sd	s0,8(sp)
 586:	0800                	add	s0,sp,16
  for(; *s; s++)
 588:	00054783          	lbu	a5,0(a0)
 58c:	cb99                	beqz	a5,5a2 <strchr+0x20>
    if(*s == c)
 58e:	00f58763          	beq	a1,a5,59c <strchr+0x1a>
  for(; *s; s++)
 592:	0505                	add	a0,a0,1
 594:	00054783          	lbu	a5,0(a0)
 598:	fbfd                	bnez	a5,58e <strchr+0xc>
      return (char*)s;
  return 0;
 59a:	4501                	li	a0,0
}
 59c:	6422                	ld	s0,8(sp)
 59e:	0141                	add	sp,sp,16
 5a0:	8082                	ret
  return 0;
 5a2:	4501                	li	a0,0
 5a4:	bfe5                	j	59c <strchr+0x1a>

00000000000005a6 <gets>:

char*
gets(char *buf, int max)
{
 5a6:	711d                	add	sp,sp,-96
 5a8:	ec86                	sd	ra,88(sp)
 5aa:	e8a2                	sd	s0,80(sp)
 5ac:	e4a6                	sd	s1,72(sp)
 5ae:	e0ca                	sd	s2,64(sp)
 5b0:	fc4e                	sd	s3,56(sp)
 5b2:	f852                	sd	s4,48(sp)
 5b4:	f456                	sd	s5,40(sp)
 5b6:	f05a                	sd	s6,32(sp)
 5b8:	ec5e                	sd	s7,24(sp)
 5ba:	1080                	add	s0,sp,96
 5bc:	8baa                	mv	s7,a0
 5be:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 5c0:	892a                	mv	s2,a0
 5c2:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 5c4:	4aa9                	li	s5,10
 5c6:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 5c8:	89a6                	mv	s3,s1
 5ca:	2485                	addw	s1,s1,1
 5cc:	0344d863          	bge	s1,s4,5fc <gets+0x56>
    cc = read(0, &c, 1);
 5d0:	4605                	li	a2,1
 5d2:	faf40593          	add	a1,s0,-81
 5d6:	4501                	li	a0,0
 5d8:	00000097          	auipc	ra,0x0
 5dc:	19a080e7          	jalr	410(ra) # 772 <read>
    if(cc < 1)
 5e0:	00a05e63          	blez	a0,5fc <gets+0x56>
    buf[i++] = c;
 5e4:	faf44783          	lbu	a5,-81(s0)
 5e8:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 5ec:	01578763          	beq	a5,s5,5fa <gets+0x54>
 5f0:	0905                	add	s2,s2,1
 5f2:	fd679be3          	bne	a5,s6,5c8 <gets+0x22>
  for(i=0; i+1 < max; ){
 5f6:	89a6                	mv	s3,s1
 5f8:	a011                	j	5fc <gets+0x56>
 5fa:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 5fc:	99de                	add	s3,s3,s7
 5fe:	00098023          	sb	zero,0(s3) # 199a000 <base+0x1994ff0>
  return buf;
}
 602:	855e                	mv	a0,s7
 604:	60e6                	ld	ra,88(sp)
 606:	6446                	ld	s0,80(sp)
 608:	64a6                	ld	s1,72(sp)
 60a:	6906                	ld	s2,64(sp)
 60c:	79e2                	ld	s3,56(sp)
 60e:	7a42                	ld	s4,48(sp)
 610:	7aa2                	ld	s5,40(sp)
 612:	7b02                	ld	s6,32(sp)
 614:	6be2                	ld	s7,24(sp)
 616:	6125                	add	sp,sp,96
 618:	8082                	ret

000000000000061a <stat>:

int
stat(const char *n, struct stat *st)
{
 61a:	1101                	add	sp,sp,-32
 61c:	ec06                	sd	ra,24(sp)
 61e:	e822                	sd	s0,16(sp)
 620:	e426                	sd	s1,8(sp)
 622:	e04a                	sd	s2,0(sp)
 624:	1000                	add	s0,sp,32
 626:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 628:	4581                	li	a1,0
 62a:	00000097          	auipc	ra,0x0
 62e:	170080e7          	jalr	368(ra) # 79a <open>
  if(fd < 0)
 632:	02054563          	bltz	a0,65c <stat+0x42>
 636:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 638:	85ca                	mv	a1,s2
 63a:	00000097          	auipc	ra,0x0
 63e:	178080e7          	jalr	376(ra) # 7b2 <fstat>
 642:	892a                	mv	s2,a0
  close(fd);
 644:	8526                	mv	a0,s1
 646:	00000097          	auipc	ra,0x0
 64a:	13c080e7          	jalr	316(ra) # 782 <close>
  return r;
}
 64e:	854a                	mv	a0,s2
 650:	60e2                	ld	ra,24(sp)
 652:	6442                	ld	s0,16(sp)
 654:	64a2                	ld	s1,8(sp)
 656:	6902                	ld	s2,0(sp)
 658:	6105                	add	sp,sp,32
 65a:	8082                	ret
    return -1;
 65c:	597d                	li	s2,-1
 65e:	bfc5                	j	64e <stat+0x34>

0000000000000660 <atoi>:

int
atoi(const char *s)
{
 660:	1141                	add	sp,sp,-16
 662:	e422                	sd	s0,8(sp)
 664:	0800                	add	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 666:	00054683          	lbu	a3,0(a0)
 66a:	fd06879b          	addw	a5,a3,-48 # fd0 <digits+0x1d0>
 66e:	0ff7f793          	zext.b	a5,a5
 672:	4625                	li	a2,9
 674:	02f66863          	bltu	a2,a5,6a4 <atoi+0x44>
 678:	872a                	mv	a4,a0
  n = 0;
 67a:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 67c:	0705                	add	a4,a4,1
 67e:	0025179b          	sllw	a5,a0,0x2
 682:	9fa9                	addw	a5,a5,a0
 684:	0017979b          	sllw	a5,a5,0x1
 688:	9fb5                	addw	a5,a5,a3
 68a:	fd07851b          	addw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 68e:	00074683          	lbu	a3,0(a4)
 692:	fd06879b          	addw	a5,a3,-48
 696:	0ff7f793          	zext.b	a5,a5
 69a:	fef671e3          	bgeu	a2,a5,67c <atoi+0x1c>
  return n;
}
 69e:	6422                	ld	s0,8(sp)
 6a0:	0141                	add	sp,sp,16
 6a2:	8082                	ret
  n = 0;
 6a4:	4501                	li	a0,0
 6a6:	bfe5                	j	69e <atoi+0x3e>

00000000000006a8 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 6a8:	1141                	add	sp,sp,-16
 6aa:	e422                	sd	s0,8(sp)
 6ac:	0800                	add	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 6ae:	02b57463          	bgeu	a0,a1,6d6 <memmove+0x2e>
    while(n-- > 0)
 6b2:	00c05f63          	blez	a2,6d0 <memmove+0x28>
 6b6:	1602                	sll	a2,a2,0x20
 6b8:	9201                	srl	a2,a2,0x20
 6ba:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 6be:	872a                	mv	a4,a0
      *dst++ = *src++;
 6c0:	0585                	add	a1,a1,1
 6c2:	0705                	add	a4,a4,1
 6c4:	fff5c683          	lbu	a3,-1(a1)
 6c8:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 6cc:	fee79ae3          	bne	a5,a4,6c0 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 6d0:	6422                	ld	s0,8(sp)
 6d2:	0141                	add	sp,sp,16
 6d4:	8082                	ret
    dst += n;
 6d6:	00c50733          	add	a4,a0,a2
    src += n;
 6da:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 6dc:	fec05ae3          	blez	a2,6d0 <memmove+0x28>
 6e0:	fff6079b          	addw	a5,a2,-1
 6e4:	1782                	sll	a5,a5,0x20
 6e6:	9381                	srl	a5,a5,0x20
 6e8:	fff7c793          	not	a5,a5
 6ec:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 6ee:	15fd                	add	a1,a1,-1
 6f0:	177d                	add	a4,a4,-1
 6f2:	0005c683          	lbu	a3,0(a1)
 6f6:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 6fa:	fee79ae3          	bne	a5,a4,6ee <memmove+0x46>
 6fe:	bfc9                	j	6d0 <memmove+0x28>

0000000000000700 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 700:	1141                	add	sp,sp,-16
 702:	e422                	sd	s0,8(sp)
 704:	0800                	add	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 706:	ca05                	beqz	a2,736 <memcmp+0x36>
 708:	fff6069b          	addw	a3,a2,-1
 70c:	1682                	sll	a3,a3,0x20
 70e:	9281                	srl	a3,a3,0x20
 710:	0685                	add	a3,a3,1
 712:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 714:	00054783          	lbu	a5,0(a0)
 718:	0005c703          	lbu	a4,0(a1)
 71c:	00e79863          	bne	a5,a4,72c <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 720:	0505                	add	a0,a0,1
    p2++;
 722:	0585                	add	a1,a1,1
  while (n-- > 0) {
 724:	fed518e3          	bne	a0,a3,714 <memcmp+0x14>
  }
  return 0;
 728:	4501                	li	a0,0
 72a:	a019                	j	730 <memcmp+0x30>
      return *p1 - *p2;
 72c:	40e7853b          	subw	a0,a5,a4
}
 730:	6422                	ld	s0,8(sp)
 732:	0141                	add	sp,sp,16
 734:	8082                	ret
  return 0;
 736:	4501                	li	a0,0
 738:	bfe5                	j	730 <memcmp+0x30>

000000000000073a <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 73a:	1141                	add	sp,sp,-16
 73c:	e406                	sd	ra,8(sp)
 73e:	e022                	sd	s0,0(sp)
 740:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
 742:	00000097          	auipc	ra,0x0
 746:	f66080e7          	jalr	-154(ra) # 6a8 <memmove>
}
 74a:	60a2                	ld	ra,8(sp)
 74c:	6402                	ld	s0,0(sp)
 74e:	0141                	add	sp,sp,16
 750:	8082                	ret

0000000000000752 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 752:	4885                	li	a7,1
 ecall
 754:	00000073          	ecall
 ret
 758:	8082                	ret

000000000000075a <exit>:
.global exit
exit:
 li a7, SYS_exit
 75a:	4889                	li	a7,2
 ecall
 75c:	00000073          	ecall
 ret
 760:	8082                	ret

0000000000000762 <wait>:
.global wait
wait:
 li a7, SYS_wait
 762:	488d                	li	a7,3
 ecall
 764:	00000073          	ecall
 ret
 768:	8082                	ret

000000000000076a <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 76a:	4891                	li	a7,4
 ecall
 76c:	00000073          	ecall
 ret
 770:	8082                	ret

0000000000000772 <read>:
.global read
read:
 li a7, SYS_read
 772:	4895                	li	a7,5
 ecall
 774:	00000073          	ecall
 ret
 778:	8082                	ret

000000000000077a <write>:
.global write
write:
 li a7, SYS_write
 77a:	48c1                	li	a7,16
 ecall
 77c:	00000073          	ecall
 ret
 780:	8082                	ret

0000000000000782 <close>:
.global close
close:
 li a7, SYS_close
 782:	48d5                	li	a7,21
 ecall
 784:	00000073          	ecall
 ret
 788:	8082                	ret

000000000000078a <kill>:
.global kill
kill:
 li a7, SYS_kill
 78a:	4899                	li	a7,6
 ecall
 78c:	00000073          	ecall
 ret
 790:	8082                	ret

0000000000000792 <exec>:
.global exec
exec:
 li a7, SYS_exec
 792:	489d                	li	a7,7
 ecall
 794:	00000073          	ecall
 ret
 798:	8082                	ret

000000000000079a <open>:
.global open
open:
 li a7, SYS_open
 79a:	48bd                	li	a7,15
 ecall
 79c:	00000073          	ecall
 ret
 7a0:	8082                	ret

00000000000007a2 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 7a2:	48c5                	li	a7,17
 ecall
 7a4:	00000073          	ecall
 ret
 7a8:	8082                	ret

00000000000007aa <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 7aa:	48c9                	li	a7,18
 ecall
 7ac:	00000073          	ecall
 ret
 7b0:	8082                	ret

00000000000007b2 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 7b2:	48a1                	li	a7,8
 ecall
 7b4:	00000073          	ecall
 ret
 7b8:	8082                	ret

00000000000007ba <link>:
.global link
link:
 li a7, SYS_link
 7ba:	48cd                	li	a7,19
 ecall
 7bc:	00000073          	ecall
 ret
 7c0:	8082                	ret

00000000000007c2 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 7c2:	48d1                	li	a7,20
 ecall
 7c4:	00000073          	ecall
 ret
 7c8:	8082                	ret

00000000000007ca <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 7ca:	48a5                	li	a7,9
 ecall
 7cc:	00000073          	ecall
 ret
 7d0:	8082                	ret

00000000000007d2 <dup>:
.global dup
dup:
 li a7, SYS_dup
 7d2:	48a9                	li	a7,10
 ecall
 7d4:	00000073          	ecall
 ret
 7d8:	8082                	ret

00000000000007da <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 7da:	48ad                	li	a7,11
 ecall
 7dc:	00000073          	ecall
 ret
 7e0:	8082                	ret

00000000000007e2 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 7e2:	48b1                	li	a7,12
 ecall
 7e4:	00000073          	ecall
 ret
 7e8:	8082                	ret

00000000000007ea <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 7ea:	48b5                	li	a7,13
 ecall
 7ec:	00000073          	ecall
 ret
 7f0:	8082                	ret

00000000000007f2 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 7f2:	48b9                	li	a7,14
 ecall
 7f4:	00000073          	ecall
 ret
 7f8:	8082                	ret

00000000000007fa <waitx>:
.global waitx
waitx:
 li a7, SYS_waitx
 7fa:	48d9                	li	a7,22
 ecall
 7fc:	00000073          	ecall
 ret
 800:	8082                	ret

0000000000000802 <getreadcount>:
.global getreadcount
getreadcount:
 li a7, SYS_getreadcount
 802:	48dd                	li	a7,23
 ecall
 804:	00000073          	ecall
 ret
 808:	8082                	ret

000000000000080a <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 80a:	1101                	add	sp,sp,-32
 80c:	ec06                	sd	ra,24(sp)
 80e:	e822                	sd	s0,16(sp)
 810:	1000                	add	s0,sp,32
 812:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 816:	4605                	li	a2,1
 818:	fef40593          	add	a1,s0,-17
 81c:	00000097          	auipc	ra,0x0
 820:	f5e080e7          	jalr	-162(ra) # 77a <write>
}
 824:	60e2                	ld	ra,24(sp)
 826:	6442                	ld	s0,16(sp)
 828:	6105                	add	sp,sp,32
 82a:	8082                	ret

000000000000082c <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 82c:	7139                	add	sp,sp,-64
 82e:	fc06                	sd	ra,56(sp)
 830:	f822                	sd	s0,48(sp)
 832:	f426                	sd	s1,40(sp)
 834:	f04a                	sd	s2,32(sp)
 836:	ec4e                	sd	s3,24(sp)
 838:	0080                	add	s0,sp,64
 83a:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 83c:	c299                	beqz	a3,842 <printint+0x16>
 83e:	0805c963          	bltz	a1,8d0 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 842:	2581                	sext.w	a1,a1
  neg = 0;
 844:	4881                	li	a7,0
 846:	fc040693          	add	a3,s0,-64
  }

  i = 0;
 84a:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 84c:	2601                	sext.w	a2,a2
 84e:	00000517          	auipc	a0,0x0
 852:	5b250513          	add	a0,a0,1458 # e00 <digits>
 856:	883a                	mv	a6,a4
 858:	2705                	addw	a4,a4,1
 85a:	02c5f7bb          	remuw	a5,a1,a2
 85e:	1782                	sll	a5,a5,0x20
 860:	9381                	srl	a5,a5,0x20
 862:	97aa                	add	a5,a5,a0
 864:	0007c783          	lbu	a5,0(a5)
 868:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 86c:	0005879b          	sext.w	a5,a1
 870:	02c5d5bb          	divuw	a1,a1,a2
 874:	0685                	add	a3,a3,1
 876:	fec7f0e3          	bgeu	a5,a2,856 <printint+0x2a>
  if(neg)
 87a:	00088c63          	beqz	a7,892 <printint+0x66>
    buf[i++] = '-';
 87e:	fd070793          	add	a5,a4,-48
 882:	00878733          	add	a4,a5,s0
 886:	02d00793          	li	a5,45
 88a:	fef70823          	sb	a5,-16(a4)
 88e:	0028071b          	addw	a4,a6,2

  while(--i >= 0)
 892:	02e05863          	blez	a4,8c2 <printint+0x96>
 896:	fc040793          	add	a5,s0,-64
 89a:	00e78933          	add	s2,a5,a4
 89e:	fff78993          	add	s3,a5,-1
 8a2:	99ba                	add	s3,s3,a4
 8a4:	377d                	addw	a4,a4,-1
 8a6:	1702                	sll	a4,a4,0x20
 8a8:	9301                	srl	a4,a4,0x20
 8aa:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 8ae:	fff94583          	lbu	a1,-1(s2)
 8b2:	8526                	mv	a0,s1
 8b4:	00000097          	auipc	ra,0x0
 8b8:	f56080e7          	jalr	-170(ra) # 80a <putc>
  while(--i >= 0)
 8bc:	197d                	add	s2,s2,-1
 8be:	ff3918e3          	bne	s2,s3,8ae <printint+0x82>
}
 8c2:	70e2                	ld	ra,56(sp)
 8c4:	7442                	ld	s0,48(sp)
 8c6:	74a2                	ld	s1,40(sp)
 8c8:	7902                	ld	s2,32(sp)
 8ca:	69e2                	ld	s3,24(sp)
 8cc:	6121                	add	sp,sp,64
 8ce:	8082                	ret
    x = -xx;
 8d0:	40b005bb          	negw	a1,a1
    neg = 1;
 8d4:	4885                	li	a7,1
    x = -xx;
 8d6:	bf85                	j	846 <printint+0x1a>

00000000000008d8 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 8d8:	715d                	add	sp,sp,-80
 8da:	e486                	sd	ra,72(sp)
 8dc:	e0a2                	sd	s0,64(sp)
 8de:	fc26                	sd	s1,56(sp)
 8e0:	f84a                	sd	s2,48(sp)
 8e2:	f44e                	sd	s3,40(sp)
 8e4:	f052                	sd	s4,32(sp)
 8e6:	ec56                	sd	s5,24(sp)
 8e8:	e85a                	sd	s6,16(sp)
 8ea:	e45e                	sd	s7,8(sp)
 8ec:	e062                	sd	s8,0(sp)
 8ee:	0880                	add	s0,sp,80
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 8f0:	0005c903          	lbu	s2,0(a1)
 8f4:	18090c63          	beqz	s2,a8c <vprintf+0x1b4>
 8f8:	8aaa                	mv	s5,a0
 8fa:	8bb2                	mv	s7,a2
 8fc:	00158493          	add	s1,a1,1
  state = 0;
 900:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 902:	02500a13          	li	s4,37
 906:	4b55                	li	s6,21
 908:	a839                	j	926 <vprintf+0x4e>
        putc(fd, c);
 90a:	85ca                	mv	a1,s2
 90c:	8556                	mv	a0,s5
 90e:	00000097          	auipc	ra,0x0
 912:	efc080e7          	jalr	-260(ra) # 80a <putc>
 916:	a019                	j	91c <vprintf+0x44>
    } else if(state == '%'){
 918:	01498d63          	beq	s3,s4,932 <vprintf+0x5a>
  for(i = 0; fmt[i]; i++){
 91c:	0485                	add	s1,s1,1
 91e:	fff4c903          	lbu	s2,-1(s1)
 922:	16090563          	beqz	s2,a8c <vprintf+0x1b4>
    if(state == 0){
 926:	fe0999e3          	bnez	s3,918 <vprintf+0x40>
      if(c == '%'){
 92a:	ff4910e3          	bne	s2,s4,90a <vprintf+0x32>
        state = '%';
 92e:	89d2                	mv	s3,s4
 930:	b7f5                	j	91c <vprintf+0x44>
      if(c == 'd'){
 932:	13490263          	beq	s2,s4,a56 <vprintf+0x17e>
 936:	f9d9079b          	addw	a5,s2,-99
 93a:	0ff7f793          	zext.b	a5,a5
 93e:	12fb6563          	bltu	s6,a5,a68 <vprintf+0x190>
 942:	f9d9079b          	addw	a5,s2,-99
 946:	0ff7f713          	zext.b	a4,a5
 94a:	10eb6f63          	bltu	s6,a4,a68 <vprintf+0x190>
 94e:	00271793          	sll	a5,a4,0x2
 952:	00000717          	auipc	a4,0x0
 956:	45670713          	add	a4,a4,1110 # da8 <malloc+0x21e>
 95a:	97ba                	add	a5,a5,a4
 95c:	439c                	lw	a5,0(a5)
 95e:	97ba                	add	a5,a5,a4
 960:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 962:	008b8913          	add	s2,s7,8
 966:	4685                	li	a3,1
 968:	4629                	li	a2,10
 96a:	000ba583          	lw	a1,0(s7)
 96e:	8556                	mv	a0,s5
 970:	00000097          	auipc	ra,0x0
 974:	ebc080e7          	jalr	-324(ra) # 82c <printint>
 978:	8bca                	mv	s7,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 97a:	4981                	li	s3,0
 97c:	b745                	j	91c <vprintf+0x44>
        printint(fd, va_arg(ap, uint64), 10, 0);
 97e:	008b8913          	add	s2,s7,8
 982:	4681                	li	a3,0
 984:	4629                	li	a2,10
 986:	000ba583          	lw	a1,0(s7)
 98a:	8556                	mv	a0,s5
 98c:	00000097          	auipc	ra,0x0
 990:	ea0080e7          	jalr	-352(ra) # 82c <printint>
 994:	8bca                	mv	s7,s2
      state = 0;
 996:	4981                	li	s3,0
 998:	b751                	j	91c <vprintf+0x44>
        printint(fd, va_arg(ap, int), 16, 0);
 99a:	008b8913          	add	s2,s7,8
 99e:	4681                	li	a3,0
 9a0:	4641                	li	a2,16
 9a2:	000ba583          	lw	a1,0(s7)
 9a6:	8556                	mv	a0,s5
 9a8:	00000097          	auipc	ra,0x0
 9ac:	e84080e7          	jalr	-380(ra) # 82c <printint>
 9b0:	8bca                	mv	s7,s2
      state = 0;
 9b2:	4981                	li	s3,0
 9b4:	b7a5                	j	91c <vprintf+0x44>
        printptr(fd, va_arg(ap, uint64));
 9b6:	008b8c13          	add	s8,s7,8
 9ba:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 9be:	03000593          	li	a1,48
 9c2:	8556                	mv	a0,s5
 9c4:	00000097          	auipc	ra,0x0
 9c8:	e46080e7          	jalr	-442(ra) # 80a <putc>
  putc(fd, 'x');
 9cc:	07800593          	li	a1,120
 9d0:	8556                	mv	a0,s5
 9d2:	00000097          	auipc	ra,0x0
 9d6:	e38080e7          	jalr	-456(ra) # 80a <putc>
 9da:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 9dc:	00000b97          	auipc	s7,0x0
 9e0:	424b8b93          	add	s7,s7,1060 # e00 <digits>
 9e4:	03c9d793          	srl	a5,s3,0x3c
 9e8:	97de                	add	a5,a5,s7
 9ea:	0007c583          	lbu	a1,0(a5)
 9ee:	8556                	mv	a0,s5
 9f0:	00000097          	auipc	ra,0x0
 9f4:	e1a080e7          	jalr	-486(ra) # 80a <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 9f8:	0992                	sll	s3,s3,0x4
 9fa:	397d                	addw	s2,s2,-1
 9fc:	fe0914e3          	bnez	s2,9e4 <vprintf+0x10c>
        printptr(fd, va_arg(ap, uint64));
 a00:	8be2                	mv	s7,s8
      state = 0;
 a02:	4981                	li	s3,0
 a04:	bf21                	j	91c <vprintf+0x44>
        s = va_arg(ap, char*);
 a06:	008b8993          	add	s3,s7,8
 a0a:	000bb903          	ld	s2,0(s7)
        if(s == 0)
 a0e:	02090163          	beqz	s2,a30 <vprintf+0x158>
        while(*s != 0){
 a12:	00094583          	lbu	a1,0(s2)
 a16:	c9a5                	beqz	a1,a86 <vprintf+0x1ae>
          putc(fd, *s);
 a18:	8556                	mv	a0,s5
 a1a:	00000097          	auipc	ra,0x0
 a1e:	df0080e7          	jalr	-528(ra) # 80a <putc>
          s++;
 a22:	0905                	add	s2,s2,1
        while(*s != 0){
 a24:	00094583          	lbu	a1,0(s2)
 a28:	f9e5                	bnez	a1,a18 <vprintf+0x140>
        s = va_arg(ap, char*);
 a2a:	8bce                	mv	s7,s3
      state = 0;
 a2c:	4981                	li	s3,0
 a2e:	b5fd                	j	91c <vprintf+0x44>
          s = "(null)";
 a30:	00000917          	auipc	s2,0x0
 a34:	37090913          	add	s2,s2,880 # da0 <malloc+0x216>
        while(*s != 0){
 a38:	02800593          	li	a1,40
 a3c:	bff1                	j	a18 <vprintf+0x140>
        putc(fd, va_arg(ap, uint));
 a3e:	008b8913          	add	s2,s7,8
 a42:	000bc583          	lbu	a1,0(s7)
 a46:	8556                	mv	a0,s5
 a48:	00000097          	auipc	ra,0x0
 a4c:	dc2080e7          	jalr	-574(ra) # 80a <putc>
 a50:	8bca                	mv	s7,s2
      state = 0;
 a52:	4981                	li	s3,0
 a54:	b5e1                	j	91c <vprintf+0x44>
        putc(fd, c);
 a56:	02500593          	li	a1,37
 a5a:	8556                	mv	a0,s5
 a5c:	00000097          	auipc	ra,0x0
 a60:	dae080e7          	jalr	-594(ra) # 80a <putc>
      state = 0;
 a64:	4981                	li	s3,0
 a66:	bd5d                	j	91c <vprintf+0x44>
        putc(fd, '%');
 a68:	02500593          	li	a1,37
 a6c:	8556                	mv	a0,s5
 a6e:	00000097          	auipc	ra,0x0
 a72:	d9c080e7          	jalr	-612(ra) # 80a <putc>
        putc(fd, c);
 a76:	85ca                	mv	a1,s2
 a78:	8556                	mv	a0,s5
 a7a:	00000097          	auipc	ra,0x0
 a7e:	d90080e7          	jalr	-624(ra) # 80a <putc>
      state = 0;
 a82:	4981                	li	s3,0
 a84:	bd61                	j	91c <vprintf+0x44>
        s = va_arg(ap, char*);
 a86:	8bce                	mv	s7,s3
      state = 0;
 a88:	4981                	li	s3,0
 a8a:	bd49                	j	91c <vprintf+0x44>
    }
  }
}
 a8c:	60a6                	ld	ra,72(sp)
 a8e:	6406                	ld	s0,64(sp)
 a90:	74e2                	ld	s1,56(sp)
 a92:	7942                	ld	s2,48(sp)
 a94:	79a2                	ld	s3,40(sp)
 a96:	7a02                	ld	s4,32(sp)
 a98:	6ae2                	ld	s5,24(sp)
 a9a:	6b42                	ld	s6,16(sp)
 a9c:	6ba2                	ld	s7,8(sp)
 a9e:	6c02                	ld	s8,0(sp)
 aa0:	6161                	add	sp,sp,80
 aa2:	8082                	ret

0000000000000aa4 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 aa4:	715d                	add	sp,sp,-80
 aa6:	ec06                	sd	ra,24(sp)
 aa8:	e822                	sd	s0,16(sp)
 aaa:	1000                	add	s0,sp,32
 aac:	e010                	sd	a2,0(s0)
 aae:	e414                	sd	a3,8(s0)
 ab0:	e818                	sd	a4,16(s0)
 ab2:	ec1c                	sd	a5,24(s0)
 ab4:	03043023          	sd	a6,32(s0)
 ab8:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 abc:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 ac0:	8622                	mv	a2,s0
 ac2:	00000097          	auipc	ra,0x0
 ac6:	e16080e7          	jalr	-490(ra) # 8d8 <vprintf>
}
 aca:	60e2                	ld	ra,24(sp)
 acc:	6442                	ld	s0,16(sp)
 ace:	6161                	add	sp,sp,80
 ad0:	8082                	ret

0000000000000ad2 <printf>:

void
printf(const char *fmt, ...)
{
 ad2:	711d                	add	sp,sp,-96
 ad4:	ec06                	sd	ra,24(sp)
 ad6:	e822                	sd	s0,16(sp)
 ad8:	1000                	add	s0,sp,32
 ada:	e40c                	sd	a1,8(s0)
 adc:	e810                	sd	a2,16(s0)
 ade:	ec14                	sd	a3,24(s0)
 ae0:	f018                	sd	a4,32(s0)
 ae2:	f41c                	sd	a5,40(s0)
 ae4:	03043823          	sd	a6,48(s0)
 ae8:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 aec:	00840613          	add	a2,s0,8
 af0:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 af4:	85aa                	mv	a1,a0
 af6:	4505                	li	a0,1
 af8:	00000097          	auipc	ra,0x0
 afc:	de0080e7          	jalr	-544(ra) # 8d8 <vprintf>
}
 b00:	60e2                	ld	ra,24(sp)
 b02:	6442                	ld	s0,16(sp)
 b04:	6125                	add	sp,sp,96
 b06:	8082                	ret

0000000000000b08 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 b08:	1141                	add	sp,sp,-16
 b0a:	e422                	sd	s0,8(sp)
 b0c:	0800                	add	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 b0e:	ff050693          	add	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 b12:	00000797          	auipc	a5,0x0
 b16:	4f67b783          	ld	a5,1270(a5) # 1008 <freep>
 b1a:	a02d                	j	b44 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 b1c:	4618                	lw	a4,8(a2)
 b1e:	9f2d                	addw	a4,a4,a1
 b20:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 b24:	6398                	ld	a4,0(a5)
 b26:	6310                	ld	a2,0(a4)
 b28:	a83d                	j	b66 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 b2a:	ff852703          	lw	a4,-8(a0)
 b2e:	9f31                	addw	a4,a4,a2
 b30:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 b32:	ff053683          	ld	a3,-16(a0)
 b36:	a091                	j	b7a <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 b38:	6398                	ld	a4,0(a5)
 b3a:	00e7e463          	bltu	a5,a4,b42 <free+0x3a>
 b3e:	00e6ea63          	bltu	a3,a4,b52 <free+0x4a>
{
 b42:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 b44:	fed7fae3          	bgeu	a5,a3,b38 <free+0x30>
 b48:	6398                	ld	a4,0(a5)
 b4a:	00e6e463          	bltu	a3,a4,b52 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 b4e:	fee7eae3          	bltu	a5,a4,b42 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 b52:	ff852583          	lw	a1,-8(a0)
 b56:	6390                	ld	a2,0(a5)
 b58:	02059813          	sll	a6,a1,0x20
 b5c:	01c85713          	srl	a4,a6,0x1c
 b60:	9736                	add	a4,a4,a3
 b62:	fae60de3          	beq	a2,a4,b1c <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 b66:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 b6a:	4790                	lw	a2,8(a5)
 b6c:	02061593          	sll	a1,a2,0x20
 b70:	01c5d713          	srl	a4,a1,0x1c
 b74:	973e                	add	a4,a4,a5
 b76:	fae68ae3          	beq	a3,a4,b2a <free+0x22>
    p->s.ptr = bp->s.ptr;
 b7a:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 b7c:	00000717          	auipc	a4,0x0
 b80:	48f73623          	sd	a5,1164(a4) # 1008 <freep>
}
 b84:	6422                	ld	s0,8(sp)
 b86:	0141                	add	sp,sp,16
 b88:	8082                	ret

0000000000000b8a <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 b8a:	7139                	add	sp,sp,-64
 b8c:	fc06                	sd	ra,56(sp)
 b8e:	f822                	sd	s0,48(sp)
 b90:	f426                	sd	s1,40(sp)
 b92:	f04a                	sd	s2,32(sp)
 b94:	ec4e                	sd	s3,24(sp)
 b96:	e852                	sd	s4,16(sp)
 b98:	e456                	sd	s5,8(sp)
 b9a:	e05a                	sd	s6,0(sp)
 b9c:	0080                	add	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 b9e:	02051493          	sll	s1,a0,0x20
 ba2:	9081                	srl	s1,s1,0x20
 ba4:	04bd                	add	s1,s1,15
 ba6:	8091                	srl	s1,s1,0x4
 ba8:	0014899b          	addw	s3,s1,1
 bac:	0485                	add	s1,s1,1
  if((prevp = freep) == 0){
 bae:	00000517          	auipc	a0,0x0
 bb2:	45a53503          	ld	a0,1114(a0) # 1008 <freep>
 bb6:	c515                	beqz	a0,be2 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 bb8:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 bba:	4798                	lw	a4,8(a5)
 bbc:	02977f63          	bgeu	a4,s1,bfa <malloc+0x70>
  if(nu < 4096)
 bc0:	8a4e                	mv	s4,s3
 bc2:	0009871b          	sext.w	a4,s3
 bc6:	6685                	lui	a3,0x1
 bc8:	00d77363          	bgeu	a4,a3,bce <malloc+0x44>
 bcc:	6a05                	lui	s4,0x1
 bce:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 bd2:	004a1a1b          	sllw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 bd6:	00000917          	auipc	s2,0x0
 bda:	43290913          	add	s2,s2,1074 # 1008 <freep>
  if(p == (char*)-1)
 bde:	5afd                	li	s5,-1
 be0:	a895                	j	c54 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 be2:	00004797          	auipc	a5,0x4
 be6:	42e78793          	add	a5,a5,1070 # 5010 <base>
 bea:	00000717          	auipc	a4,0x0
 bee:	40f73f23          	sd	a5,1054(a4) # 1008 <freep>
 bf2:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 bf4:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 bf8:	b7e1                	j	bc0 <malloc+0x36>
      if(p->s.size == nunits)
 bfa:	02e48c63          	beq	s1,a4,c32 <malloc+0xa8>
        p->s.size -= nunits;
 bfe:	4137073b          	subw	a4,a4,s3
 c02:	c798                	sw	a4,8(a5)
        p += p->s.size;
 c04:	02071693          	sll	a3,a4,0x20
 c08:	01c6d713          	srl	a4,a3,0x1c
 c0c:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 c0e:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 c12:	00000717          	auipc	a4,0x0
 c16:	3ea73b23          	sd	a0,1014(a4) # 1008 <freep>
      return (void*)(p + 1);
 c1a:	01078513          	add	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 c1e:	70e2                	ld	ra,56(sp)
 c20:	7442                	ld	s0,48(sp)
 c22:	74a2                	ld	s1,40(sp)
 c24:	7902                	ld	s2,32(sp)
 c26:	69e2                	ld	s3,24(sp)
 c28:	6a42                	ld	s4,16(sp)
 c2a:	6aa2                	ld	s5,8(sp)
 c2c:	6b02                	ld	s6,0(sp)
 c2e:	6121                	add	sp,sp,64
 c30:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 c32:	6398                	ld	a4,0(a5)
 c34:	e118                	sd	a4,0(a0)
 c36:	bff1                	j	c12 <malloc+0x88>
  hp->s.size = nu;
 c38:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 c3c:	0541                	add	a0,a0,16
 c3e:	00000097          	auipc	ra,0x0
 c42:	eca080e7          	jalr	-310(ra) # b08 <free>
  return freep;
 c46:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 c4a:	d971                	beqz	a0,c1e <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 c4c:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 c4e:	4798                	lw	a4,8(a5)
 c50:	fa9775e3          	bgeu	a4,s1,bfa <malloc+0x70>
    if(p == freep)
 c54:	00093703          	ld	a4,0(s2)
 c58:	853e                	mv	a0,a5
 c5a:	fef719e3          	bne	a4,a5,c4c <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 c5e:	8552                	mv	a0,s4
 c60:	00000097          	auipc	ra,0x0
 c64:	b82080e7          	jalr	-1150(ra) # 7e2 <sbrk>
  if(p == (char*)-1)
 c68:	fd5518e3          	bne	a0,s5,c38 <malloc+0xae>
        return 0;
 c6c:	4501                	li	a0,0
 c6e:	bf45                	j	c1e <malloc+0x94>
