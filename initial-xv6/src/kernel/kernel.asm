
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a5010113          	add	sp,sp,-1456 # 80008a50 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	add	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	add	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	add	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	sllw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	add	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	sll	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	sll	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	8c070713          	add	a4,a4,-1856 # 80008910 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	08e78793          	add	a5,a5,142 # 800060f0 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	or	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	or	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	add	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	add	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	add	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	add	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fdbc27f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	add	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	e9078793          	add	a5,a5,-368 # 80000f3c <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	add	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	or	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srl	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	add	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	add	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	add	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	add	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	636080e7          	jalr	1590(ra) # 80002760 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	780080e7          	jalr	1920(ra) # 800008ba <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addw	s2,s2,1
    80000144:	0485                	add	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	add	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	711d                	add	sp,sp,-96
    80000166:	ec86                	sd	ra,88(sp)
    80000168:	e8a2                	sd	s0,80(sp)
    8000016a:	e4a6                	sd	s1,72(sp)
    8000016c:	e0ca                	sd	s2,64(sp)
    8000016e:	fc4e                	sd	s3,56(sp)
    80000170:	f852                	sd	s4,48(sp)
    80000172:	f456                	sd	s5,40(sp)
    80000174:	f05a                	sd	s6,32(sp)
    80000176:	ec5e                	sd	s7,24(sp)
    80000178:	1080                	add	s0,sp,96
    8000017a:	8aaa                	mv	s5,a0
    8000017c:	8a2e                	mv	s4,a1
    8000017e:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000180:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000184:	00011517          	auipc	a0,0x11
    80000188:	8cc50513          	add	a0,a0,-1844 # 80010a50 <cons>
    8000018c:	00001097          	auipc	ra,0x1
    80000190:	b10080e7          	jalr	-1264(ra) # 80000c9c <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000194:	00011497          	auipc	s1,0x11
    80000198:	8bc48493          	add	s1,s1,-1860 # 80010a50 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    8000019c:	00011917          	auipc	s2,0x11
    800001a0:	94c90913          	add	s2,s2,-1716 # 80010ae8 <cons+0x98>
  while(n > 0){
    800001a4:	09305263          	blez	s3,80000228 <consoleread+0xc4>
    while(cons.r == cons.w){
    800001a8:	0984a783          	lw	a5,152(s1)
    800001ac:	09c4a703          	lw	a4,156(s1)
    800001b0:	02f71763          	bne	a4,a5,800001de <consoleread+0x7a>
      if(killed(myproc())){
    800001b4:	00002097          	auipc	ra,0x2
    800001b8:	88e080e7          	jalr	-1906(ra) # 80001a42 <myproc>
    800001bc:	00002097          	auipc	ra,0x2
    800001c0:	3ee080e7          	jalr	1006(ra) # 800025aa <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	12c080e7          	jalr	300(ra) # 800022f6 <sleep>
    while(cons.r == cons.w){
    800001d2:	0984a783          	lw	a5,152(s1)
    800001d6:	09c4a703          	lw	a4,156(s1)
    800001da:	fcf70de3          	beq	a4,a5,800001b4 <consoleread+0x50>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001de:	00011717          	auipc	a4,0x11
    800001e2:	87270713          	add	a4,a4,-1934 # 80010a50 <cons>
    800001e6:	0017869b          	addw	a3,a5,1
    800001ea:	08d72c23          	sw	a3,152(a4)
    800001ee:	07f7f693          	and	a3,a5,127
    800001f2:	9736                	add	a4,a4,a3
    800001f4:	01874703          	lbu	a4,24(a4)
    800001f8:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    800001fc:	4691                	li	a3,4
    800001fe:	06db8463          	beq	s7,a3,80000266 <consoleread+0x102>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    80000202:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	faf40613          	add	a2,s0,-81
    8000020c:	85d2                	mv	a1,s4
    8000020e:	8556                	mv	a0,s5
    80000210:	00002097          	auipc	ra,0x2
    80000214:	4fa080e7          	jalr	1274(ra) # 8000270a <either_copyout>
    80000218:	57fd                	li	a5,-1
    8000021a:	00f50763          	beq	a0,a5,80000228 <consoleread+0xc4>
      break;

    dst++;
    8000021e:	0a05                	add	s4,s4,1
    --n;
    80000220:	39fd                	addw	s3,s3,-1

    if(c == '\n'){
    80000222:	47a9                	li	a5,10
    80000224:	f8fb90e3          	bne	s7,a5,800001a4 <consoleread+0x40>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	82850513          	add	a0,a0,-2008 # 80010a50 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	b20080e7          	jalr	-1248(ra) # 80000d50 <release>

  return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xec>
        release(&cons.lock);
    8000023e:	00011517          	auipc	a0,0x11
    80000242:	81250513          	add	a0,a0,-2030 # 80010a50 <cons>
    80000246:	00001097          	auipc	ra,0x1
    8000024a:	b0a080e7          	jalr	-1270(ra) # 80000d50 <release>
        return -1;
    8000024e:	557d                	li	a0,-1
}
    80000250:	60e6                	ld	ra,88(sp)
    80000252:	6446                	ld	s0,80(sp)
    80000254:	64a6                	ld	s1,72(sp)
    80000256:	6906                	ld	s2,64(sp)
    80000258:	79e2                	ld	s3,56(sp)
    8000025a:	7a42                	ld	s4,48(sp)
    8000025c:	7aa2                	ld	s5,40(sp)
    8000025e:	7b02                	ld	s6,32(sp)
    80000260:	6be2                	ld	s7,24(sp)
    80000262:	6125                	add	sp,sp,96
    80000264:	8082                	ret
      if(n < target){
    80000266:	0009871b          	sext.w	a4,s3
    8000026a:	fb677fe3          	bgeu	a4,s6,80000228 <consoleread+0xc4>
        cons.r--;
    8000026e:	00011717          	auipc	a4,0x11
    80000272:	86f72d23          	sw	a5,-1926(a4) # 80010ae8 <cons+0x98>
    80000276:	bf4d                	j	80000228 <consoleread+0xc4>

0000000080000278 <consputc>:
{
    80000278:	1141                	add	sp,sp,-16
    8000027a:	e406                	sd	ra,8(sp)
    8000027c:	e022                	sd	s0,0(sp)
    8000027e:	0800                	add	s0,sp,16
  if(c == BACKSPACE){
    80000280:	10000793          	li	a5,256
    80000284:	00f50a63          	beq	a0,a5,80000298 <consputc+0x20>
    uartputc_sync(c);
    80000288:	00000097          	auipc	ra,0x0
    8000028c:	560080e7          	jalr	1376(ra) # 800007e8 <uartputc_sync>
}
    80000290:	60a2                	ld	ra,8(sp)
    80000292:	6402                	ld	s0,0(sp)
    80000294:	0141                	add	sp,sp,16
    80000296:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000298:	4521                	li	a0,8
    8000029a:	00000097          	auipc	ra,0x0
    8000029e:	54e080e7          	jalr	1358(ra) # 800007e8 <uartputc_sync>
    800002a2:	02000513          	li	a0,32
    800002a6:	00000097          	auipc	ra,0x0
    800002aa:	542080e7          	jalr	1346(ra) # 800007e8 <uartputc_sync>
    800002ae:	4521                	li	a0,8
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	538080e7          	jalr	1336(ra) # 800007e8 <uartputc_sync>
    800002b8:	bfe1                	j	80000290 <consputc+0x18>

00000000800002ba <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002ba:	1101                	add	sp,sp,-32
    800002bc:	ec06                	sd	ra,24(sp)
    800002be:	e822                	sd	s0,16(sp)
    800002c0:	e426                	sd	s1,8(sp)
    800002c2:	e04a                	sd	s2,0(sp)
    800002c4:	1000                	add	s0,sp,32
    800002c6:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002c8:	00010517          	auipc	a0,0x10
    800002cc:	78850513          	add	a0,a0,1928 # 80010a50 <cons>
    800002d0:	00001097          	auipc	ra,0x1
    800002d4:	9cc080e7          	jalr	-1588(ra) # 80000c9c <acquire>

  switch(c){
    800002d8:	47d5                	li	a5,21
    800002da:	0af48663          	beq	s1,a5,80000386 <consoleintr+0xcc>
    800002de:	0297ca63          	blt	a5,s1,80000312 <consoleintr+0x58>
    800002e2:	47a1                	li	a5,8
    800002e4:	0ef48763          	beq	s1,a5,800003d2 <consoleintr+0x118>
    800002e8:	47c1                	li	a5,16
    800002ea:	10f49a63          	bne	s1,a5,800003fe <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002ee:	00002097          	auipc	ra,0x2
    800002f2:	4c8080e7          	jalr	1224(ra) # 800027b6 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f6:	00010517          	auipc	a0,0x10
    800002fa:	75a50513          	add	a0,a0,1882 # 80010a50 <cons>
    800002fe:	00001097          	auipc	ra,0x1
    80000302:	a52080e7          	jalr	-1454(ra) # 80000d50 <release>
}
    80000306:	60e2                	ld	ra,24(sp)
    80000308:	6442                	ld	s0,16(sp)
    8000030a:	64a2                	ld	s1,8(sp)
    8000030c:	6902                	ld	s2,0(sp)
    8000030e:	6105                	add	sp,sp,32
    80000310:	8082                	ret
  switch(c){
    80000312:	07f00793          	li	a5,127
    80000316:	0af48e63          	beq	s1,a5,800003d2 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031a:	00010717          	auipc	a4,0x10
    8000031e:	73670713          	add	a4,a4,1846 # 80010a50 <cons>
    80000322:	0a072783          	lw	a5,160(a4)
    80000326:	09872703          	lw	a4,152(a4)
    8000032a:	9f99                	subw	a5,a5,a4
    8000032c:	07f00713          	li	a4,127
    80000330:	fcf763e3          	bltu	a4,a5,800002f6 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000334:	47b5                	li	a5,13
    80000336:	0cf48763          	beq	s1,a5,80000404 <consoleintr+0x14a>
      consputc(c);
    8000033a:	8526                	mv	a0,s1
    8000033c:	00000097          	auipc	ra,0x0
    80000340:	f3c080e7          	jalr	-196(ra) # 80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000344:	00010797          	auipc	a5,0x10
    80000348:	70c78793          	add	a5,a5,1804 # 80010a50 <cons>
    8000034c:	0a07a683          	lw	a3,160(a5)
    80000350:	0016871b          	addw	a4,a3,1
    80000354:	0007061b          	sext.w	a2,a4
    80000358:	0ae7a023          	sw	a4,160(a5)
    8000035c:	07f6f693          	and	a3,a3,127
    80000360:	97b6                	add	a5,a5,a3
    80000362:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000366:	47a9                	li	a5,10
    80000368:	0cf48563          	beq	s1,a5,80000432 <consoleintr+0x178>
    8000036c:	4791                	li	a5,4
    8000036e:	0cf48263          	beq	s1,a5,80000432 <consoleintr+0x178>
    80000372:	00010797          	auipc	a5,0x10
    80000376:	7767a783          	lw	a5,1910(a5) # 80010ae8 <cons+0x98>
    8000037a:	9f1d                	subw	a4,a4,a5
    8000037c:	08000793          	li	a5,128
    80000380:	f6f71be3          	bne	a4,a5,800002f6 <consoleintr+0x3c>
    80000384:	a07d                	j	80000432 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000386:	00010717          	auipc	a4,0x10
    8000038a:	6ca70713          	add	a4,a4,1738 # 80010a50 <cons>
    8000038e:	0a072783          	lw	a5,160(a4)
    80000392:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000396:	00010497          	auipc	s1,0x10
    8000039a:	6ba48493          	add	s1,s1,1722 # 80010a50 <cons>
    while(cons.e != cons.w &&
    8000039e:	4929                	li	s2,10
    800003a0:	f4f70be3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a4:	37fd                	addw	a5,a5,-1
    800003a6:	07f7f713          	and	a4,a5,127
    800003aa:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ac:	01874703          	lbu	a4,24(a4)
    800003b0:	f52703e3          	beq	a4,s2,800002f6 <consoleintr+0x3c>
      cons.e--;
    800003b4:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003b8:	10000513          	li	a0,256
    800003bc:	00000097          	auipc	ra,0x0
    800003c0:	ebc080e7          	jalr	-324(ra) # 80000278 <consputc>
    while(cons.e != cons.w &&
    800003c4:	0a04a783          	lw	a5,160(s1)
    800003c8:	09c4a703          	lw	a4,156(s1)
    800003cc:	fcf71ce3          	bne	a4,a5,800003a4 <consoleintr+0xea>
    800003d0:	b71d                	j	800002f6 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d2:	00010717          	auipc	a4,0x10
    800003d6:	67e70713          	add	a4,a4,1662 # 80010a50 <cons>
    800003da:	0a072783          	lw	a5,160(a4)
    800003de:	09c72703          	lw	a4,156(a4)
    800003e2:	f0f70ae3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
      cons.e--;
    800003e6:	37fd                	addw	a5,a5,-1
    800003e8:	00010717          	auipc	a4,0x10
    800003ec:	70f72423          	sw	a5,1800(a4) # 80010af0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f0:	10000513          	li	a0,256
    800003f4:	00000097          	auipc	ra,0x0
    800003f8:	e84080e7          	jalr	-380(ra) # 80000278 <consputc>
    800003fc:	bded                	j	800002f6 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800003fe:	ee048ce3          	beqz	s1,800002f6 <consoleintr+0x3c>
    80000402:	bf21                	j	8000031a <consoleintr+0x60>
      consputc(c);
    80000404:	4529                	li	a0,10
    80000406:	00000097          	auipc	ra,0x0
    8000040a:	e72080e7          	jalr	-398(ra) # 80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000040e:	00010797          	auipc	a5,0x10
    80000412:	64278793          	add	a5,a5,1602 # 80010a50 <cons>
    80000416:	0a07a703          	lw	a4,160(a5)
    8000041a:	0017069b          	addw	a3,a4,1
    8000041e:	0006861b          	sext.w	a2,a3
    80000422:	0ad7a023          	sw	a3,160(a5)
    80000426:	07f77713          	and	a4,a4,127
    8000042a:	97ba                	add	a5,a5,a4
    8000042c:	4729                	li	a4,10
    8000042e:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000432:	00010797          	auipc	a5,0x10
    80000436:	6ac7ad23          	sw	a2,1722(a5) # 80010aec <cons+0x9c>
        wakeup(&cons.r);
    8000043a:	00010517          	auipc	a0,0x10
    8000043e:	6ae50513          	add	a0,a0,1710 # 80010ae8 <cons+0x98>
    80000442:	00002097          	auipc	ra,0x2
    80000446:	f18080e7          	jalr	-232(ra) # 8000235a <wakeup>
    8000044a:	b575                	j	800002f6 <consoleintr+0x3c>

000000008000044c <consoleinit>:

void
consoleinit(void)
{
    8000044c:	1141                	add	sp,sp,-16
    8000044e:	e406                	sd	ra,8(sp)
    80000450:	e022                	sd	s0,0(sp)
    80000452:	0800                	add	s0,sp,16
  initlock(&cons.lock, "cons");
    80000454:	00008597          	auipc	a1,0x8
    80000458:	bbc58593          	add	a1,a1,-1092 # 80008010 <etext+0x10>
    8000045c:	00010517          	auipc	a0,0x10
    80000460:	5f450513          	add	a0,a0,1524 # 80010a50 <cons>
    80000464:	00000097          	auipc	ra,0x0
    80000468:	7a8080e7          	jalr	1960(ra) # 80000c0c <initlock>

  uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	32c080e7          	jalr	812(ra) # 80000798 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000474:	00241797          	auipc	a5,0x241
    80000478:	f7478793          	add	a5,a5,-140 # 802413e8 <devsw>
    8000047c:	00000717          	auipc	a4,0x0
    80000480:	ce870713          	add	a4,a4,-792 # 80000164 <consoleread>
    80000484:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	c7a70713          	add	a4,a4,-902 # 80000100 <consolewrite>
    8000048e:	ef98                	sd	a4,24(a5)
}
    80000490:	60a2                	ld	ra,8(sp)
    80000492:	6402                	ld	s0,0(sp)
    80000494:	0141                	add	sp,sp,16
    80000496:	8082                	ret

0000000080000498 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000498:	7179                	add	sp,sp,-48
    8000049a:	f406                	sd	ra,40(sp)
    8000049c:	f022                	sd	s0,32(sp)
    8000049e:	ec26                	sd	s1,24(sp)
    800004a0:	e84a                	sd	s2,16(sp)
    800004a2:	1800                	add	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a4:	c219                	beqz	a2,800004aa <printint+0x12>
    800004a6:	08054763          	bltz	a0,80000534 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004aa:	2501                	sext.w	a0,a0
    800004ac:	4881                	li	a7,0
    800004ae:	fd040693          	add	a3,s0,-48

  i = 0;
    800004b2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b4:	2581                	sext.w	a1,a1
    800004b6:	00008617          	auipc	a2,0x8
    800004ba:	b8a60613          	add	a2,a2,-1142 # 80008040 <digits>
    800004be:	883a                	mv	a6,a4
    800004c0:	2705                	addw	a4,a4,1
    800004c2:	02b577bb          	remuw	a5,a0,a1
    800004c6:	1782                	sll	a5,a5,0x20
    800004c8:	9381                	srl	a5,a5,0x20
    800004ca:	97b2                	add	a5,a5,a2
    800004cc:	0007c783          	lbu	a5,0(a5)
    800004d0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d4:	0005079b          	sext.w	a5,a0
    800004d8:	02b5553b          	divuw	a0,a0,a1
    800004dc:	0685                	add	a3,a3,1
    800004de:	feb7f0e3          	bgeu	a5,a1,800004be <printint+0x26>

  if(sign)
    800004e2:	00088c63          	beqz	a7,800004fa <printint+0x62>
    buf[i++] = '-';
    800004e6:	fe070793          	add	a5,a4,-32
    800004ea:	00878733          	add	a4,a5,s0
    800004ee:	02d00793          	li	a5,45
    800004f2:	fef70823          	sb	a5,-16(a4)
    800004f6:	0028071b          	addw	a4,a6,2

  while(--i >= 0)
    800004fa:	02e05763          	blez	a4,80000528 <printint+0x90>
    800004fe:	fd040793          	add	a5,s0,-48
    80000502:	00e784b3          	add	s1,a5,a4
    80000506:	fff78913          	add	s2,a5,-1
    8000050a:	993a                	add	s2,s2,a4
    8000050c:	377d                	addw	a4,a4,-1
    8000050e:	1702                	sll	a4,a4,0x20
    80000510:	9301                	srl	a4,a4,0x20
    80000512:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000516:	fff4c503          	lbu	a0,-1(s1)
    8000051a:	00000097          	auipc	ra,0x0
    8000051e:	d5e080e7          	jalr	-674(ra) # 80000278 <consputc>
  while(--i >= 0)
    80000522:	14fd                	add	s1,s1,-1
    80000524:	ff2499e3          	bne	s1,s2,80000516 <printint+0x7e>
}
    80000528:	70a2                	ld	ra,40(sp)
    8000052a:	7402                	ld	s0,32(sp)
    8000052c:	64e2                	ld	s1,24(sp)
    8000052e:	6942                	ld	s2,16(sp)
    80000530:	6145                	add	sp,sp,48
    80000532:	8082                	ret
    x = -xx;
    80000534:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000538:	4885                	li	a7,1
    x = -xx;
    8000053a:	bf95                	j	800004ae <printint+0x16>

000000008000053c <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053c:	1101                	add	sp,sp,-32
    8000053e:	ec06                	sd	ra,24(sp)
    80000540:	e822                	sd	s0,16(sp)
    80000542:	e426                	sd	s1,8(sp)
    80000544:	1000                	add	s0,sp,32
    80000546:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000548:	00010797          	auipc	a5,0x10
    8000054c:	5c07a423          	sw	zero,1480(a5) # 80010b10 <pr+0x18>
  printf("panic: ");
    80000550:	00008517          	auipc	a0,0x8
    80000554:	ac850513          	add	a0,a0,-1336 # 80008018 <etext+0x18>
    80000558:	00000097          	auipc	ra,0x0
    8000055c:	02e080e7          	jalr	46(ra) # 80000586 <printf>
  printf(s);
    80000560:	8526                	mv	a0,s1
    80000562:	00000097          	auipc	ra,0x0
    80000566:	024080e7          	jalr	36(ra) # 80000586 <printf>
  printf("\n");
    8000056a:	00008517          	auipc	a0,0x8
    8000056e:	cce50513          	add	a0,a0,-818 # 80008238 <digits+0x1f8>
    80000572:	00000097          	auipc	ra,0x0
    80000576:	014080e7          	jalr	20(ra) # 80000586 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057a:	4785                	li	a5,1
    8000057c:	00008717          	auipc	a4,0x8
    80000580:	34f72a23          	sw	a5,852(a4) # 800088d0 <panicked>
  for(;;)
    80000584:	a001                	j	80000584 <panic+0x48>

0000000080000586 <printf>:
{
    80000586:	7131                	add	sp,sp,-192
    80000588:	fc86                	sd	ra,120(sp)
    8000058a:	f8a2                	sd	s0,112(sp)
    8000058c:	f4a6                	sd	s1,104(sp)
    8000058e:	f0ca                	sd	s2,96(sp)
    80000590:	ecce                	sd	s3,88(sp)
    80000592:	e8d2                	sd	s4,80(sp)
    80000594:	e4d6                	sd	s5,72(sp)
    80000596:	e0da                	sd	s6,64(sp)
    80000598:	fc5e                	sd	s7,56(sp)
    8000059a:	f862                	sd	s8,48(sp)
    8000059c:	f466                	sd	s9,40(sp)
    8000059e:	f06a                	sd	s10,32(sp)
    800005a0:	ec6e                	sd	s11,24(sp)
    800005a2:	0100                	add	s0,sp,128
    800005a4:	8a2a                	mv	s4,a0
    800005a6:	e40c                	sd	a1,8(s0)
    800005a8:	e810                	sd	a2,16(s0)
    800005aa:	ec14                	sd	a3,24(s0)
    800005ac:	f018                	sd	a4,32(s0)
    800005ae:	f41c                	sd	a5,40(s0)
    800005b0:	03043823          	sd	a6,48(s0)
    800005b4:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005b8:	00010d97          	auipc	s11,0x10
    800005bc:	558dad83          	lw	s11,1368(s11) # 80010b10 <pr+0x18>
  if(locking)
    800005c0:	020d9b63          	bnez	s11,800005f6 <printf+0x70>
  if (fmt == 0)
    800005c4:	040a0263          	beqz	s4,80000608 <printf+0x82>
  va_start(ap, fmt);
    800005c8:	00840793          	add	a5,s0,8
    800005cc:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d0:	000a4503          	lbu	a0,0(s4)
    800005d4:	14050f63          	beqz	a0,80000732 <printf+0x1ac>
    800005d8:	4981                	li	s3,0
    if(c != '%'){
    800005da:	02500a93          	li	s5,37
    switch(c){
    800005de:	07000b93          	li	s7,112
  consputc('x');
    800005e2:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e4:	00008b17          	auipc	s6,0x8
    800005e8:	a5cb0b13          	add	s6,s6,-1444 # 80008040 <digits>
    switch(c){
    800005ec:	07300c93          	li	s9,115
    800005f0:	06400c13          	li	s8,100
    800005f4:	a82d                	j	8000062e <printf+0xa8>
    acquire(&pr.lock);
    800005f6:	00010517          	auipc	a0,0x10
    800005fa:	50250513          	add	a0,a0,1282 # 80010af8 <pr>
    800005fe:	00000097          	auipc	ra,0x0
    80000602:	69e080e7          	jalr	1694(ra) # 80000c9c <acquire>
    80000606:	bf7d                	j	800005c4 <printf+0x3e>
    panic("null fmt");
    80000608:	00008517          	auipc	a0,0x8
    8000060c:	a2050513          	add	a0,a0,-1504 # 80008028 <etext+0x28>
    80000610:	00000097          	auipc	ra,0x0
    80000614:	f2c080e7          	jalr	-212(ra) # 8000053c <panic>
      consputc(c);
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	c60080e7          	jalr	-928(ra) # 80000278 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000620:	2985                	addw	s3,s3,1
    80000622:	013a07b3          	add	a5,s4,s3
    80000626:	0007c503          	lbu	a0,0(a5)
    8000062a:	10050463          	beqz	a0,80000732 <printf+0x1ac>
    if(c != '%'){
    8000062e:	ff5515e3          	bne	a0,s5,80000618 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000632:	2985                	addw	s3,s3,1
    80000634:	013a07b3          	add	a5,s4,s3
    80000638:	0007c783          	lbu	a5,0(a5)
    8000063c:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000640:	cbed                	beqz	a5,80000732 <printf+0x1ac>
    switch(c){
    80000642:	05778a63          	beq	a5,s7,80000696 <printf+0x110>
    80000646:	02fbf663          	bgeu	s7,a5,80000672 <printf+0xec>
    8000064a:	09978863          	beq	a5,s9,800006da <printf+0x154>
    8000064e:	07800713          	li	a4,120
    80000652:	0ce79563          	bne	a5,a4,8000071c <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000656:	f8843783          	ld	a5,-120(s0)
    8000065a:	00878713          	add	a4,a5,8
    8000065e:	f8e43423          	sd	a4,-120(s0)
    80000662:	4605                	li	a2,1
    80000664:	85ea                	mv	a1,s10
    80000666:	4388                	lw	a0,0(a5)
    80000668:	00000097          	auipc	ra,0x0
    8000066c:	e30080e7          	jalr	-464(ra) # 80000498 <printint>
      break;
    80000670:	bf45                	j	80000620 <printf+0x9a>
    switch(c){
    80000672:	09578f63          	beq	a5,s5,80000710 <printf+0x18a>
    80000676:	0b879363          	bne	a5,s8,8000071c <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067a:	f8843783          	ld	a5,-120(s0)
    8000067e:	00878713          	add	a4,a5,8
    80000682:	f8e43423          	sd	a4,-120(s0)
    80000686:	4605                	li	a2,1
    80000688:	45a9                	li	a1,10
    8000068a:	4388                	lw	a0,0(a5)
    8000068c:	00000097          	auipc	ra,0x0
    80000690:	e0c080e7          	jalr	-500(ra) # 80000498 <printint>
      break;
    80000694:	b771                	j	80000620 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000696:	f8843783          	ld	a5,-120(s0)
    8000069a:	00878713          	add	a4,a5,8
    8000069e:	f8e43423          	sd	a4,-120(s0)
    800006a2:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a6:	03000513          	li	a0,48
    800006aa:	00000097          	auipc	ra,0x0
    800006ae:	bce080e7          	jalr	-1074(ra) # 80000278 <consputc>
  consputc('x');
    800006b2:	07800513          	li	a0,120
    800006b6:	00000097          	auipc	ra,0x0
    800006ba:	bc2080e7          	jalr	-1086(ra) # 80000278 <consputc>
    800006be:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c0:	03c95793          	srl	a5,s2,0x3c
    800006c4:	97da                	add	a5,a5,s6
    800006c6:	0007c503          	lbu	a0,0(a5)
    800006ca:	00000097          	auipc	ra,0x0
    800006ce:	bae080e7          	jalr	-1106(ra) # 80000278 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d2:	0912                	sll	s2,s2,0x4
    800006d4:	34fd                	addw	s1,s1,-1
    800006d6:	f4ed                	bnez	s1,800006c0 <printf+0x13a>
    800006d8:	b7a1                	j	80000620 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006da:	f8843783          	ld	a5,-120(s0)
    800006de:	00878713          	add	a4,a5,8
    800006e2:	f8e43423          	sd	a4,-120(s0)
    800006e6:	6384                	ld	s1,0(a5)
    800006e8:	cc89                	beqz	s1,80000702 <printf+0x17c>
      for(; *s; s++)
    800006ea:	0004c503          	lbu	a0,0(s1)
    800006ee:	d90d                	beqz	a0,80000620 <printf+0x9a>
        consputc(*s);
    800006f0:	00000097          	auipc	ra,0x0
    800006f4:	b88080e7          	jalr	-1144(ra) # 80000278 <consputc>
      for(; *s; s++)
    800006f8:	0485                	add	s1,s1,1
    800006fa:	0004c503          	lbu	a0,0(s1)
    800006fe:	f96d                	bnez	a0,800006f0 <printf+0x16a>
    80000700:	b705                	j	80000620 <printf+0x9a>
        s = "(null)";
    80000702:	00008497          	auipc	s1,0x8
    80000706:	91e48493          	add	s1,s1,-1762 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070a:	02800513          	li	a0,40
    8000070e:	b7cd                	j	800006f0 <printf+0x16a>
      consputc('%');
    80000710:	8556                	mv	a0,s5
    80000712:	00000097          	auipc	ra,0x0
    80000716:	b66080e7          	jalr	-1178(ra) # 80000278 <consputc>
      break;
    8000071a:	b719                	j	80000620 <printf+0x9a>
      consputc('%');
    8000071c:	8556                	mv	a0,s5
    8000071e:	00000097          	auipc	ra,0x0
    80000722:	b5a080e7          	jalr	-1190(ra) # 80000278 <consputc>
      consputc(c);
    80000726:	8526                	mv	a0,s1
    80000728:	00000097          	auipc	ra,0x0
    8000072c:	b50080e7          	jalr	-1200(ra) # 80000278 <consputc>
      break;
    80000730:	bdc5                	j	80000620 <printf+0x9a>
  if(locking)
    80000732:	020d9163          	bnez	s11,80000754 <printf+0x1ce>
}
    80000736:	70e6                	ld	ra,120(sp)
    80000738:	7446                	ld	s0,112(sp)
    8000073a:	74a6                	ld	s1,104(sp)
    8000073c:	7906                	ld	s2,96(sp)
    8000073e:	69e6                	ld	s3,88(sp)
    80000740:	6a46                	ld	s4,80(sp)
    80000742:	6aa6                	ld	s5,72(sp)
    80000744:	6b06                	ld	s6,64(sp)
    80000746:	7be2                	ld	s7,56(sp)
    80000748:	7c42                	ld	s8,48(sp)
    8000074a:	7ca2                	ld	s9,40(sp)
    8000074c:	7d02                	ld	s10,32(sp)
    8000074e:	6de2                	ld	s11,24(sp)
    80000750:	6129                	add	sp,sp,192
    80000752:	8082                	ret
    release(&pr.lock);
    80000754:	00010517          	auipc	a0,0x10
    80000758:	3a450513          	add	a0,a0,932 # 80010af8 <pr>
    8000075c:	00000097          	auipc	ra,0x0
    80000760:	5f4080e7          	jalr	1524(ra) # 80000d50 <release>
}
    80000764:	bfc9                	j	80000736 <printf+0x1b0>

0000000080000766 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000766:	1101                	add	sp,sp,-32
    80000768:	ec06                	sd	ra,24(sp)
    8000076a:	e822                	sd	s0,16(sp)
    8000076c:	e426                	sd	s1,8(sp)
    8000076e:	1000                	add	s0,sp,32
  initlock(&pr.lock, "pr");
    80000770:	00010497          	auipc	s1,0x10
    80000774:	38848493          	add	s1,s1,904 # 80010af8 <pr>
    80000778:	00008597          	auipc	a1,0x8
    8000077c:	8c058593          	add	a1,a1,-1856 # 80008038 <etext+0x38>
    80000780:	8526                	mv	a0,s1
    80000782:	00000097          	auipc	ra,0x0
    80000786:	48a080e7          	jalr	1162(ra) # 80000c0c <initlock>
  pr.locking = 1;
    8000078a:	4785                	li	a5,1
    8000078c:	cc9c                	sw	a5,24(s1)
}
    8000078e:	60e2                	ld	ra,24(sp)
    80000790:	6442                	ld	s0,16(sp)
    80000792:	64a2                	ld	s1,8(sp)
    80000794:	6105                	add	sp,sp,32
    80000796:	8082                	ret

0000000080000798 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000798:	1141                	add	sp,sp,-16
    8000079a:	e406                	sd	ra,8(sp)
    8000079c:	e022                	sd	s0,0(sp)
    8000079e:	0800                	add	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a0:	100007b7          	lui	a5,0x10000
    800007a4:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a8:	f8000713          	li	a4,-128
    800007ac:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b0:	470d                	li	a4,3
    800007b2:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b6:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007ba:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007be:	469d                	li	a3,7
    800007c0:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c4:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c8:	00008597          	auipc	a1,0x8
    800007cc:	89058593          	add	a1,a1,-1904 # 80008058 <digits+0x18>
    800007d0:	00010517          	auipc	a0,0x10
    800007d4:	34850513          	add	a0,a0,840 # 80010b18 <uart_tx_lock>
    800007d8:	00000097          	auipc	ra,0x0
    800007dc:	434080e7          	jalr	1076(ra) # 80000c0c <initlock>
}
    800007e0:	60a2                	ld	ra,8(sp)
    800007e2:	6402                	ld	s0,0(sp)
    800007e4:	0141                	add	sp,sp,16
    800007e6:	8082                	ret

00000000800007e8 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e8:	1101                	add	sp,sp,-32
    800007ea:	ec06                	sd	ra,24(sp)
    800007ec:	e822                	sd	s0,16(sp)
    800007ee:	e426                	sd	s1,8(sp)
    800007f0:	1000                	add	s0,sp,32
    800007f2:	84aa                	mv	s1,a0
  push_off();
    800007f4:	00000097          	auipc	ra,0x0
    800007f8:	45c080e7          	jalr	1116(ra) # 80000c50 <push_off>

  if(panicked){
    800007fc:	00008797          	auipc	a5,0x8
    80000800:	0d47a783          	lw	a5,212(a5) # 800088d0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000804:	10000737          	lui	a4,0x10000
  if(panicked){
    80000808:	c391                	beqz	a5,8000080c <uartputc_sync+0x24>
    for(;;)
    8000080a:	a001                	j	8000080a <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000810:	0207f793          	and	a5,a5,32
    80000814:	dfe5                	beqz	a5,8000080c <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000816:	0ff4f513          	zext.b	a0,s1
    8000081a:	100007b7          	lui	a5,0x10000
    8000081e:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000822:	00000097          	auipc	ra,0x0
    80000826:	4ce080e7          	jalr	1230(ra) # 80000cf0 <pop_off>
}
    8000082a:	60e2                	ld	ra,24(sp)
    8000082c:	6442                	ld	s0,16(sp)
    8000082e:	64a2                	ld	s1,8(sp)
    80000830:	6105                	add	sp,sp,32
    80000832:	8082                	ret

0000000080000834 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000834:	00008797          	auipc	a5,0x8
    80000838:	0a47b783          	ld	a5,164(a5) # 800088d8 <uart_tx_r>
    8000083c:	00008717          	auipc	a4,0x8
    80000840:	0a473703          	ld	a4,164(a4) # 800088e0 <uart_tx_w>
    80000844:	06f70a63          	beq	a4,a5,800008b8 <uartstart+0x84>
{
    80000848:	7139                	add	sp,sp,-64
    8000084a:	fc06                	sd	ra,56(sp)
    8000084c:	f822                	sd	s0,48(sp)
    8000084e:	f426                	sd	s1,40(sp)
    80000850:	f04a                	sd	s2,32(sp)
    80000852:	ec4e                	sd	s3,24(sp)
    80000854:	e852                	sd	s4,16(sp)
    80000856:	e456                	sd	s5,8(sp)
    80000858:	0080                	add	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085a:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085e:	00010a17          	auipc	s4,0x10
    80000862:	2baa0a13          	add	s4,s4,698 # 80010b18 <uart_tx_lock>
    uart_tx_r += 1;
    80000866:	00008497          	auipc	s1,0x8
    8000086a:	07248493          	add	s1,s1,114 # 800088d8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086e:	00008997          	auipc	s3,0x8
    80000872:	07298993          	add	s3,s3,114 # 800088e0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000876:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087a:	02077713          	and	a4,a4,32
    8000087e:	c705                	beqz	a4,800008a6 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000880:	01f7f713          	and	a4,a5,31
    80000884:	9752                	add	a4,a4,s4
    80000886:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088a:	0785                	add	a5,a5,1
    8000088c:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000088e:	8526                	mv	a0,s1
    80000890:	00002097          	auipc	ra,0x2
    80000894:	aca080e7          	jalr	-1334(ra) # 8000235a <wakeup>
    
    WriteReg(THR, c);
    80000898:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089c:	609c                	ld	a5,0(s1)
    8000089e:	0009b703          	ld	a4,0(s3)
    800008a2:	fcf71ae3          	bne	a4,a5,80000876 <uartstart+0x42>
  }
}
    800008a6:	70e2                	ld	ra,56(sp)
    800008a8:	7442                	ld	s0,48(sp)
    800008aa:	74a2                	ld	s1,40(sp)
    800008ac:	7902                	ld	s2,32(sp)
    800008ae:	69e2                	ld	s3,24(sp)
    800008b0:	6a42                	ld	s4,16(sp)
    800008b2:	6aa2                	ld	s5,8(sp)
    800008b4:	6121                	add	sp,sp,64
    800008b6:	8082                	ret
    800008b8:	8082                	ret

00000000800008ba <uartputc>:
{
    800008ba:	7179                	add	sp,sp,-48
    800008bc:	f406                	sd	ra,40(sp)
    800008be:	f022                	sd	s0,32(sp)
    800008c0:	ec26                	sd	s1,24(sp)
    800008c2:	e84a                	sd	s2,16(sp)
    800008c4:	e44e                	sd	s3,8(sp)
    800008c6:	e052                	sd	s4,0(sp)
    800008c8:	1800                	add	s0,sp,48
    800008ca:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008cc:	00010517          	auipc	a0,0x10
    800008d0:	24c50513          	add	a0,a0,588 # 80010b18 <uart_tx_lock>
    800008d4:	00000097          	auipc	ra,0x0
    800008d8:	3c8080e7          	jalr	968(ra) # 80000c9c <acquire>
  if(panicked){
    800008dc:	00008797          	auipc	a5,0x8
    800008e0:	ff47a783          	lw	a5,-12(a5) # 800088d0 <panicked>
    800008e4:	e7c9                	bnez	a5,8000096e <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	ffa73703          	ld	a4,-6(a4) # 800088e0 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	fea7b783          	ld	a5,-22(a5) # 800088d8 <uart_tx_r>
    800008f6:	02078793          	add	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fa:	00010997          	auipc	s3,0x10
    800008fe:	21e98993          	add	s3,s3,542 # 80010b18 <uart_tx_lock>
    80000902:	00008497          	auipc	s1,0x8
    80000906:	fd648493          	add	s1,s1,-42 # 800088d8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090a:	00008917          	auipc	s2,0x8
    8000090e:	fd690913          	add	s2,s2,-42 # 800088e0 <uart_tx_w>
    80000912:	00e79f63          	bne	a5,a4,80000930 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00002097          	auipc	ra,0x2
    8000091e:	9dc080e7          	jalr	-1572(ra) # 800022f6 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	add	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00010497          	auipc	s1,0x10
    80000934:	1e848493          	add	s1,s1,488 # 80010b18 <uart_tx_lock>
    80000938:	01f77793          	and	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000942:	0705                	add	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	f8e7be23          	sd	a4,-100(a5) # 800088e0 <uart_tx_w>
  uartstart();
    8000094c:	00000097          	auipc	ra,0x0
    80000950:	ee8080e7          	jalr	-280(ra) # 80000834 <uartstart>
  release(&uart_tx_lock);
    80000954:	8526                	mv	a0,s1
    80000956:	00000097          	auipc	ra,0x0
    8000095a:	3fa080e7          	jalr	1018(ra) # 80000d50 <release>
}
    8000095e:	70a2                	ld	ra,40(sp)
    80000960:	7402                	ld	s0,32(sp)
    80000962:	64e2                	ld	s1,24(sp)
    80000964:	6942                	ld	s2,16(sp)
    80000966:	69a2                	ld	s3,8(sp)
    80000968:	6a02                	ld	s4,0(sp)
    8000096a:	6145                	add	sp,sp,48
    8000096c:	8082                	ret
    for(;;)
    8000096e:	a001                	j	8000096e <uartputc+0xb4>

0000000080000970 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000970:	1141                	add	sp,sp,-16
    80000972:	e422                	sd	s0,8(sp)
    80000974:	0800                	add	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000976:	100007b7          	lui	a5,0x10000
    8000097a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000097e:	8b85                	and	a5,a5,1
    80000980:	cb81                	beqz	a5,80000990 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000982:	100007b7          	lui	a5,0x10000
    80000986:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098a:	6422                	ld	s0,8(sp)
    8000098c:	0141                	add	sp,sp,16
    8000098e:	8082                	ret
    return -1;
    80000990:	557d                	li	a0,-1
    80000992:	bfe5                	j	8000098a <uartgetc+0x1a>

0000000080000994 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000994:	1101                	add	sp,sp,-32
    80000996:	ec06                	sd	ra,24(sp)
    80000998:	e822                	sd	s0,16(sp)
    8000099a:	e426                	sd	s1,8(sp)
    8000099c:	1000                	add	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000099e:	54fd                	li	s1,-1
    800009a0:	a029                	j	800009aa <uartintr+0x16>
      break;
    consoleintr(c);
    800009a2:	00000097          	auipc	ra,0x0
    800009a6:	918080e7          	jalr	-1768(ra) # 800002ba <consoleintr>
    int c = uartgetc();
    800009aa:	00000097          	auipc	ra,0x0
    800009ae:	fc6080e7          	jalr	-58(ra) # 80000970 <uartgetc>
    if(c == -1)
    800009b2:	fe9518e3          	bne	a0,s1,800009a2 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009b6:	00010497          	auipc	s1,0x10
    800009ba:	16248493          	add	s1,s1,354 # 80010b18 <uart_tx_lock>
    800009be:	8526                	mv	a0,s1
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	2dc080e7          	jalr	732(ra) # 80000c9c <acquire>
  uartstart();
    800009c8:	00000097          	auipc	ra,0x0
    800009cc:	e6c080e7          	jalr	-404(ra) # 80000834 <uartstart>
  release(&uart_tx_lock);
    800009d0:	8526                	mv	a0,s1
    800009d2:	00000097          	auipc	ra,0x0
    800009d6:	37e080e7          	jalr	894(ra) # 80000d50 <release>
}
    800009da:	60e2                	ld	ra,24(sp)
    800009dc:	6442                	ld	s0,16(sp)
    800009de:	64a2                	ld	s1,8(sp)
    800009e0:	6105                	add	sp,sp,32
    800009e2:	8082                	ret

00000000800009e4 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e4:	7179                	add	sp,sp,-48
    800009e6:	f406                	sd	ra,40(sp)
    800009e8:	f022                	sd	s0,32(sp)
    800009ea:	ec26                	sd	s1,24(sp)
    800009ec:	e84a                	sd	s2,16(sp)
    800009ee:	e44e                	sd	s3,8(sp)
    800009f0:	1800                	add	s0,sp,48
    800009f2:	84aa                	mv	s1,a0
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP){
    800009f4:	03451793          	sll	a5,a0,0x34
    800009f8:	efb9                	bnez	a5,80000a56 <kfree+0x72>
    800009fa:	00242797          	auipc	a5,0x242
    800009fe:	b8678793          	add	a5,a5,-1146 # 80242580 <end>
    80000a02:	04f56a63          	bltu	a0,a5,80000a56 <kfree+0x72>
    80000a06:	47c5                	li	a5,17
    80000a08:	07ee                	sll	a5,a5,0x1b
    80000a0a:	04f57663          	bgeu	a0,a5,80000a56 <kfree+0x72>

    printf("pa : %d\n", pa);
    panic("kfree");
  }

  acquire(&kmem.lock);
    80000a0e:	00010917          	auipc	s2,0x10
    80000a12:	14290913          	add	s2,s2,322 # 80010b50 <kmem>
    80000a16:	854a                	mv	a0,s2
    80000a18:	00000097          	auipc	ra,0x0
    80000a1c:	284080e7          	jalr	644(ra) # 80000c9c <acquire>
  int rc = --reference_count[(uint64)pa/PGSIZE] ;
    80000a20:	00c4d713          	srl	a4,s1,0xc
    80000a24:	070a                	sll	a4,a4,0x2
    80000a26:	00010797          	auipc	a5,0x10
    80000a2a:	14a78793          	add	a5,a5,330 # 80010b70 <reference_count>
    80000a2e:	97ba                	add	a5,a5,a4
    80000a30:	4398                	lw	a4,0(a5)
    80000a32:	377d                	addw	a4,a4,-1
    80000a34:	0007099b          	sext.w	s3,a4
    80000a38:	c398                	sw	a4,0(a5)

  release(&kmem.lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	314080e7          	jalr	788(ra) # 80000d50 <release>
  // Fill with junk to catch dangling refs.
  if (rc>0) return; 
    80000a44:	03305a63          	blez	s3,80000a78 <kfree+0x94>

  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}
    80000a48:	70a2                	ld	ra,40(sp)
    80000a4a:	7402                	ld	s0,32(sp)
    80000a4c:	64e2                	ld	s1,24(sp)
    80000a4e:	6942                	ld	s2,16(sp)
    80000a50:	69a2                	ld	s3,8(sp)
    80000a52:	6145                	add	sp,sp,48
    80000a54:	8082                	ret
    printf("pa : %d\n", pa);
    80000a56:	85a6                	mv	a1,s1
    80000a58:	00007517          	auipc	a0,0x7
    80000a5c:	60850513          	add	a0,a0,1544 # 80008060 <digits+0x20>
    80000a60:	00000097          	auipc	ra,0x0
    80000a64:	b26080e7          	jalr	-1242(ra) # 80000586 <printf>
    panic("kfree");
    80000a68:	00007517          	auipc	a0,0x7
    80000a6c:	60850513          	add	a0,a0,1544 # 80008070 <digits+0x30>
    80000a70:	00000097          	auipc	ra,0x0
    80000a74:	acc080e7          	jalr	-1332(ra) # 8000053c <panic>
  memset(pa, 1, PGSIZE);
    80000a78:	6605                	lui	a2,0x1
    80000a7a:	4585                	li	a1,1
    80000a7c:	8526                	mv	a0,s1
    80000a7e:	00000097          	auipc	ra,0x0
    80000a82:	31a080e7          	jalr	794(ra) # 80000d98 <memset>
  acquire(&kmem.lock);
    80000a86:	854a                	mv	a0,s2
    80000a88:	00000097          	auipc	ra,0x0
    80000a8c:	214080e7          	jalr	532(ra) # 80000c9c <acquire>
  r->next = kmem.freelist;
    80000a90:	01893783          	ld	a5,24(s2)
    80000a94:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a96:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a9a:	854a                	mv	a0,s2
    80000a9c:	00000097          	auipc	ra,0x0
    80000aa0:	2b4080e7          	jalr	692(ra) # 80000d50 <release>
    80000aa4:	b755                	j	80000a48 <kfree+0x64>

0000000080000aa6 <freerange>:
{
    80000aa6:	7139                	add	sp,sp,-64
    80000aa8:	fc06                	sd	ra,56(sp)
    80000aaa:	f822                	sd	s0,48(sp)
    80000aac:	f426                	sd	s1,40(sp)
    80000aae:	f04a                	sd	s2,32(sp)
    80000ab0:	ec4e                	sd	s3,24(sp)
    80000ab2:	e852                	sd	s4,16(sp)
    80000ab4:	e456                	sd	s5,8(sp)
    80000ab6:	e05a                	sd	s6,0(sp)
    80000ab8:	0080                	add	s0,sp,64
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000aba:	6785                	lui	a5,0x1
    80000abc:	fff78713          	add	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000ac0:	953a                	add	a0,a0,a4
    80000ac2:	777d                	lui	a4,0xfffff
    80000ac4:	00e574b3          	and	s1,a0,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    80000ac8:	97a6                	add	a5,a5,s1
    80000aca:	02f5ea63          	bltu	a1,a5,80000afe <freerange+0x58>
    80000ace:	892e                	mv	s2,a1
    reference_count[(uint64)p/PGSIZE] = 1;
    80000ad0:	00010b17          	auipc	s6,0x10
    80000ad4:	0a0b0b13          	add	s6,s6,160 # 80010b70 <reference_count>
    80000ad8:	4a85                	li	s5,1
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    80000ada:	6a05                	lui	s4,0x1
    80000adc:	6989                	lui	s3,0x2
    reference_count[(uint64)p/PGSIZE] = 1;
    80000ade:	00c4d793          	srl	a5,s1,0xc
    80000ae2:	078a                	sll	a5,a5,0x2
    80000ae4:	97da                	add	a5,a5,s6
    80000ae6:	0157a023          	sw	s5,0(a5)
    kfree(p);
    80000aea:	8526                	mv	a0,s1
    80000aec:	00000097          	auipc	ra,0x0
    80000af0:	ef8080e7          	jalr	-264(ra) # 800009e4 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    80000af4:	87a6                	mv	a5,s1
    80000af6:	94d2                	add	s1,s1,s4
    80000af8:	97ce                	add	a5,a5,s3
    80000afa:	fef972e3          	bgeu	s2,a5,80000ade <freerange+0x38>
}
    80000afe:	70e2                	ld	ra,56(sp)
    80000b00:	7442                	ld	s0,48(sp)
    80000b02:	74a2                	ld	s1,40(sp)
    80000b04:	7902                	ld	s2,32(sp)
    80000b06:	69e2                	ld	s3,24(sp)
    80000b08:	6a42                	ld	s4,16(sp)
    80000b0a:	6aa2                	ld	s5,8(sp)
    80000b0c:	6b02                	ld	s6,0(sp)
    80000b0e:	6121                	add	sp,sp,64
    80000b10:	8082                	ret

0000000080000b12 <kinit>:
{
    80000b12:	1141                	add	sp,sp,-16
    80000b14:	e406                	sd	ra,8(sp)
    80000b16:	e022                	sd	s0,0(sp)
    80000b18:	0800                	add	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b1a:	00007597          	auipc	a1,0x7
    80000b1e:	55e58593          	add	a1,a1,1374 # 80008078 <digits+0x38>
    80000b22:	00010517          	auipc	a0,0x10
    80000b26:	02e50513          	add	a0,a0,46 # 80010b50 <kmem>
    80000b2a:	00000097          	auipc	ra,0x0
    80000b2e:	0e2080e7          	jalr	226(ra) # 80000c0c <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b32:	45c5                	li	a1,17
    80000b34:	05ee                	sll	a1,a1,0x1b
    80000b36:	00242517          	auipc	a0,0x242
    80000b3a:	a4a50513          	add	a0,a0,-1462 # 80242580 <end>
    80000b3e:	00000097          	auipc	ra,0x0
    80000b42:	f68080e7          	jalr	-152(ra) # 80000aa6 <freerange>
}
    80000b46:	60a2                	ld	ra,8(sp)
    80000b48:	6402                	ld	s0,0(sp)
    80000b4a:	0141                	add	sp,sp,16
    80000b4c:	8082                	ret

0000000080000b4e <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b4e:	1101                	add	sp,sp,-32
    80000b50:	ec06                	sd	ra,24(sp)
    80000b52:	e822                	sd	s0,16(sp)
    80000b54:	e426                	sd	s1,8(sp)
    80000b56:	1000                	add	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b58:	00010497          	auipc	s1,0x10
    80000b5c:	ff848493          	add	s1,s1,-8 # 80010b50 <kmem>
    80000b60:	8526                	mv	a0,s1
    80000b62:	00000097          	auipc	ra,0x0
    80000b66:	13a080e7          	jalr	314(ra) # 80000c9c <acquire>
  r = kmem.freelist;
    80000b6a:	6c84                	ld	s1,24(s1)
  if(r){
    80000b6c:	c0b1                	beqz	s1,80000bb0 <kalloc+0x62>

    kmem.freelist = r->next; 
    80000b6e:	609c                	ld	a5,0(s1)
    80000b70:	00010517          	auipc	a0,0x10
    80000b74:	fe050513          	add	a0,a0,-32 # 80010b50 <kmem>
    80000b78:	ed1c                	sd	a5,24(a0)
    reference_count[(uint64)r/PGSIZE] = 1;
    80000b7a:	00c4d713          	srl	a4,s1,0xc
    80000b7e:	070a                	sll	a4,a4,0x2
    80000b80:	00010797          	auipc	a5,0x10
    80000b84:	ff078793          	add	a5,a5,-16 # 80010b70 <reference_count>
    80000b88:	97ba                	add	a5,a5,a4
    80000b8a:	4705                	li	a4,1
    80000b8c:	c398                	sw	a4,0(a5)
  }
  release(&kmem.lock);
    80000b8e:	00000097          	auipc	ra,0x0
    80000b92:	1c2080e7          	jalr	450(ra) # 80000d50 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b96:	6605                	lui	a2,0x1
    80000b98:	4595                	li	a1,5
    80000b9a:	8526                	mv	a0,s1
    80000b9c:	00000097          	auipc	ra,0x0
    80000ba0:	1fc080e7          	jalr	508(ra) # 80000d98 <memset>
  return (void*)r;
}
    80000ba4:	8526                	mv	a0,s1
    80000ba6:	60e2                	ld	ra,24(sp)
    80000ba8:	6442                	ld	s0,16(sp)
    80000baa:	64a2                	ld	s1,8(sp)
    80000bac:	6105                	add	sp,sp,32
    80000bae:	8082                	ret
  release(&kmem.lock);
    80000bb0:	00010517          	auipc	a0,0x10
    80000bb4:	fa050513          	add	a0,a0,-96 # 80010b50 <kmem>
    80000bb8:	00000097          	auipc	ra,0x0
    80000bbc:	198080e7          	jalr	408(ra) # 80000d50 <release>
  if(r)
    80000bc0:	b7d5                	j	80000ba4 <kalloc+0x56>

0000000080000bc2 <add_reference>:

void 
add_reference(uint64 pa){
    80000bc2:	1101                	add	sp,sp,-32
    80000bc4:	ec06                	sd	ra,24(sp)
    80000bc6:	e822                	sd	s0,16(sp)
    80000bc8:	e426                	sd	s1,8(sp)
    80000bca:	e04a                	sd	s2,0(sp)
    80000bcc:	1000                	add	s0,sp,32
    80000bce:	84aa                	mv	s1,a0
  acquire(&kmem.lock);
    80000bd0:	00010917          	auipc	s2,0x10
    80000bd4:	f8090913          	add	s2,s2,-128 # 80010b50 <kmem>
    80000bd8:	854a                	mv	a0,s2
    80000bda:	00000097          	auipc	ra,0x0
    80000bde:	0c2080e7          	jalr	194(ra) # 80000c9c <acquire>
  reference_count[(uint64)pa/PGSIZE] ++  ;
    80000be2:	80b1                	srl	s1,s1,0xc
    80000be4:	048a                	sll	s1,s1,0x2
    80000be6:	00010797          	auipc	a5,0x10
    80000bea:	f8a78793          	add	a5,a5,-118 # 80010b70 <reference_count>
    80000bee:	97a6                	add	a5,a5,s1
    80000bf0:	4398                	lw	a4,0(a5)
    80000bf2:	2705                	addw	a4,a4,1 # fffffffffffff001 <end+0xffffffff7fdbca81>
    80000bf4:	c398                	sw	a4,0(a5)
  release(&kmem.lock);
    80000bf6:	854a                	mv	a0,s2
    80000bf8:	00000097          	auipc	ra,0x0
    80000bfc:	158080e7          	jalr	344(ra) # 80000d50 <release>

    80000c00:	60e2                	ld	ra,24(sp)
    80000c02:	6442                	ld	s0,16(sp)
    80000c04:	64a2                	ld	s1,8(sp)
    80000c06:	6902                	ld	s2,0(sp)
    80000c08:	6105                	add	sp,sp,32
    80000c0a:	8082                	ret

0000000080000c0c <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000c0c:	1141                	add	sp,sp,-16
    80000c0e:	e422                	sd	s0,8(sp)
    80000c10:	0800                	add	s0,sp,16
  lk->name = name;
    80000c12:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000c14:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000c18:	00053823          	sd	zero,16(a0)
}
    80000c1c:	6422                	ld	s0,8(sp)
    80000c1e:	0141                	add	sp,sp,16
    80000c20:	8082                	ret

0000000080000c22 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c22:	411c                	lw	a5,0(a0)
    80000c24:	e399                	bnez	a5,80000c2a <holding+0x8>
    80000c26:	4501                	li	a0,0
  return r;
}
    80000c28:	8082                	ret
{
    80000c2a:	1101                	add	sp,sp,-32
    80000c2c:	ec06                	sd	ra,24(sp)
    80000c2e:	e822                	sd	s0,16(sp)
    80000c30:	e426                	sd	s1,8(sp)
    80000c32:	1000                	add	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c34:	6904                	ld	s1,16(a0)
    80000c36:	00001097          	auipc	ra,0x1
    80000c3a:	df0080e7          	jalr	-528(ra) # 80001a26 <mycpu>
    80000c3e:	40a48533          	sub	a0,s1,a0
    80000c42:	00153513          	seqz	a0,a0
}
    80000c46:	60e2                	ld	ra,24(sp)
    80000c48:	6442                	ld	s0,16(sp)
    80000c4a:	64a2                	ld	s1,8(sp)
    80000c4c:	6105                	add	sp,sp,32
    80000c4e:	8082                	ret

0000000080000c50 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c50:	1101                	add	sp,sp,-32
    80000c52:	ec06                	sd	ra,24(sp)
    80000c54:	e822                	sd	s0,16(sp)
    80000c56:	e426                	sd	s1,8(sp)
    80000c58:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c5a:	100024f3          	csrr	s1,sstatus
    80000c5e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c62:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c64:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c68:	00001097          	auipc	ra,0x1
    80000c6c:	dbe080e7          	jalr	-578(ra) # 80001a26 <mycpu>
    80000c70:	5d3c                	lw	a5,120(a0)
    80000c72:	cf89                	beqz	a5,80000c8c <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c74:	00001097          	auipc	ra,0x1
    80000c78:	db2080e7          	jalr	-590(ra) # 80001a26 <mycpu>
    80000c7c:	5d3c                	lw	a5,120(a0)
    80000c7e:	2785                	addw	a5,a5,1
    80000c80:	dd3c                	sw	a5,120(a0)
}
    80000c82:	60e2                	ld	ra,24(sp)
    80000c84:	6442                	ld	s0,16(sp)
    80000c86:	64a2                	ld	s1,8(sp)
    80000c88:	6105                	add	sp,sp,32
    80000c8a:	8082                	ret
    mycpu()->intena = old;
    80000c8c:	00001097          	auipc	ra,0x1
    80000c90:	d9a080e7          	jalr	-614(ra) # 80001a26 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c94:	8085                	srl	s1,s1,0x1
    80000c96:	8885                	and	s1,s1,1
    80000c98:	dd64                	sw	s1,124(a0)
    80000c9a:	bfe9                	j	80000c74 <push_off+0x24>

0000000080000c9c <acquire>:
{
    80000c9c:	1101                	add	sp,sp,-32
    80000c9e:	ec06                	sd	ra,24(sp)
    80000ca0:	e822                	sd	s0,16(sp)
    80000ca2:	e426                	sd	s1,8(sp)
    80000ca4:	1000                	add	s0,sp,32
    80000ca6:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000ca8:	00000097          	auipc	ra,0x0
    80000cac:	fa8080e7          	jalr	-88(ra) # 80000c50 <push_off>
  if(holding(lk))
    80000cb0:	8526                	mv	a0,s1
    80000cb2:	00000097          	auipc	ra,0x0
    80000cb6:	f70080e7          	jalr	-144(ra) # 80000c22 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000cba:	4705                	li	a4,1
  if(holding(lk))
    80000cbc:	e115                	bnez	a0,80000ce0 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000cbe:	87ba                	mv	a5,a4
    80000cc0:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000cc4:	2781                	sext.w	a5,a5
    80000cc6:	ffe5                	bnez	a5,80000cbe <acquire+0x22>
  __sync_synchronize();
    80000cc8:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000ccc:	00001097          	auipc	ra,0x1
    80000cd0:	d5a080e7          	jalr	-678(ra) # 80001a26 <mycpu>
    80000cd4:	e888                	sd	a0,16(s1)
}
    80000cd6:	60e2                	ld	ra,24(sp)
    80000cd8:	6442                	ld	s0,16(sp)
    80000cda:	64a2                	ld	s1,8(sp)
    80000cdc:	6105                	add	sp,sp,32
    80000cde:	8082                	ret
    panic("acquire");
    80000ce0:	00007517          	auipc	a0,0x7
    80000ce4:	3a050513          	add	a0,a0,928 # 80008080 <digits+0x40>
    80000ce8:	00000097          	auipc	ra,0x0
    80000cec:	854080e7          	jalr	-1964(ra) # 8000053c <panic>

0000000080000cf0 <pop_off>:

void
pop_off(void)
{
    80000cf0:	1141                	add	sp,sp,-16
    80000cf2:	e406                	sd	ra,8(sp)
    80000cf4:	e022                	sd	s0,0(sp)
    80000cf6:	0800                	add	s0,sp,16
  struct cpu *c = mycpu();
    80000cf8:	00001097          	auipc	ra,0x1
    80000cfc:	d2e080e7          	jalr	-722(ra) # 80001a26 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d00:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d04:	8b89                	and	a5,a5,2
  if(intr_get())
    80000d06:	e78d                	bnez	a5,80000d30 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d08:	5d3c                	lw	a5,120(a0)
    80000d0a:	02f05b63          	blez	a5,80000d40 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d0e:	37fd                	addw	a5,a5,-1
    80000d10:	0007871b          	sext.w	a4,a5
    80000d14:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d16:	eb09                	bnez	a4,80000d28 <pop_off+0x38>
    80000d18:	5d7c                	lw	a5,124(a0)
    80000d1a:	c799                	beqz	a5,80000d28 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d1c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d20:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d24:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d28:	60a2                	ld	ra,8(sp)
    80000d2a:	6402                	ld	s0,0(sp)
    80000d2c:	0141                	add	sp,sp,16
    80000d2e:	8082                	ret
    panic("pop_off - interruptible");
    80000d30:	00007517          	auipc	a0,0x7
    80000d34:	35850513          	add	a0,a0,856 # 80008088 <digits+0x48>
    80000d38:	00000097          	auipc	ra,0x0
    80000d3c:	804080e7          	jalr	-2044(ra) # 8000053c <panic>
    panic("pop_off");
    80000d40:	00007517          	auipc	a0,0x7
    80000d44:	36050513          	add	a0,a0,864 # 800080a0 <digits+0x60>
    80000d48:	fffff097          	auipc	ra,0xfffff
    80000d4c:	7f4080e7          	jalr	2036(ra) # 8000053c <panic>

0000000080000d50 <release>:
{
    80000d50:	1101                	add	sp,sp,-32
    80000d52:	ec06                	sd	ra,24(sp)
    80000d54:	e822                	sd	s0,16(sp)
    80000d56:	e426                	sd	s1,8(sp)
    80000d58:	1000                	add	s0,sp,32
    80000d5a:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d5c:	00000097          	auipc	ra,0x0
    80000d60:	ec6080e7          	jalr	-314(ra) # 80000c22 <holding>
    80000d64:	c115                	beqz	a0,80000d88 <release+0x38>
  lk->cpu = 0;
    80000d66:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d6a:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d6e:	0f50000f          	fence	iorw,ow
    80000d72:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d76:	00000097          	auipc	ra,0x0
    80000d7a:	f7a080e7          	jalr	-134(ra) # 80000cf0 <pop_off>
}
    80000d7e:	60e2                	ld	ra,24(sp)
    80000d80:	6442                	ld	s0,16(sp)
    80000d82:	64a2                	ld	s1,8(sp)
    80000d84:	6105                	add	sp,sp,32
    80000d86:	8082                	ret
    panic("release");
    80000d88:	00007517          	auipc	a0,0x7
    80000d8c:	32050513          	add	a0,a0,800 # 800080a8 <digits+0x68>
    80000d90:	fffff097          	auipc	ra,0xfffff
    80000d94:	7ac080e7          	jalr	1964(ra) # 8000053c <panic>

0000000080000d98 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d98:	1141                	add	sp,sp,-16
    80000d9a:	e422                	sd	s0,8(sp)
    80000d9c:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d9e:	ca19                	beqz	a2,80000db4 <memset+0x1c>
    80000da0:	87aa                	mv	a5,a0
    80000da2:	1602                	sll	a2,a2,0x20
    80000da4:	9201                	srl	a2,a2,0x20
    80000da6:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000daa:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000dae:	0785                	add	a5,a5,1
    80000db0:	fee79de3          	bne	a5,a4,80000daa <memset+0x12>
  }
  return dst;
}
    80000db4:	6422                	ld	s0,8(sp)
    80000db6:	0141                	add	sp,sp,16
    80000db8:	8082                	ret

0000000080000dba <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000dba:	1141                	add	sp,sp,-16
    80000dbc:	e422                	sd	s0,8(sp)
    80000dbe:	0800                	add	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000dc0:	ca05                	beqz	a2,80000df0 <memcmp+0x36>
    80000dc2:	fff6069b          	addw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000dc6:	1682                	sll	a3,a3,0x20
    80000dc8:	9281                	srl	a3,a3,0x20
    80000dca:	0685                	add	a3,a3,1
    80000dcc:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000dce:	00054783          	lbu	a5,0(a0)
    80000dd2:	0005c703          	lbu	a4,0(a1)
    80000dd6:	00e79863          	bne	a5,a4,80000de6 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000dda:	0505                	add	a0,a0,1
    80000ddc:	0585                	add	a1,a1,1
  while(n-- > 0){
    80000dde:	fed518e3          	bne	a0,a3,80000dce <memcmp+0x14>
  }

  return 0;
    80000de2:	4501                	li	a0,0
    80000de4:	a019                	j	80000dea <memcmp+0x30>
      return *s1 - *s2;
    80000de6:	40e7853b          	subw	a0,a5,a4
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	add	sp,sp,16
    80000dee:	8082                	ret
  return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <memcmp+0x30>

0000000080000df4 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000df4:	1141                	add	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	add	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000dfa:	c205                	beqz	a2,80000e1a <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000dfc:	02a5e263          	bltu	a1,a0,80000e20 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000e00:	1602                	sll	a2,a2,0x20
    80000e02:	9201                	srl	a2,a2,0x20
    80000e04:	00c587b3          	add	a5,a1,a2
{
    80000e08:	872a                	mv	a4,a0
      *d++ = *s++;
    80000e0a:	0585                	add	a1,a1,1
    80000e0c:	0705                	add	a4,a4,1
    80000e0e:	fff5c683          	lbu	a3,-1(a1)
    80000e12:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000e16:	fef59ae3          	bne	a1,a5,80000e0a <memmove+0x16>

  return dst;
}
    80000e1a:	6422                	ld	s0,8(sp)
    80000e1c:	0141                	add	sp,sp,16
    80000e1e:	8082                	ret
  if(s < d && s + n > d){
    80000e20:	02061693          	sll	a3,a2,0x20
    80000e24:	9281                	srl	a3,a3,0x20
    80000e26:	00d58733          	add	a4,a1,a3
    80000e2a:	fce57be3          	bgeu	a0,a4,80000e00 <memmove+0xc>
    d += n;
    80000e2e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000e30:	fff6079b          	addw	a5,a2,-1
    80000e34:	1782                	sll	a5,a5,0x20
    80000e36:	9381                	srl	a5,a5,0x20
    80000e38:	fff7c793          	not	a5,a5
    80000e3c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000e3e:	177d                	add	a4,a4,-1
    80000e40:	16fd                	add	a3,a3,-1
    80000e42:	00074603          	lbu	a2,0(a4)
    80000e46:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000e4a:	fee79ae3          	bne	a5,a4,80000e3e <memmove+0x4a>
    80000e4e:	b7f1                	j	80000e1a <memmove+0x26>

0000000080000e50 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e50:	1141                	add	sp,sp,-16
    80000e52:	e406                	sd	ra,8(sp)
    80000e54:	e022                	sd	s0,0(sp)
    80000e56:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
    80000e58:	00000097          	auipc	ra,0x0
    80000e5c:	f9c080e7          	jalr	-100(ra) # 80000df4 <memmove>
}
    80000e60:	60a2                	ld	ra,8(sp)
    80000e62:	6402                	ld	s0,0(sp)
    80000e64:	0141                	add	sp,sp,16
    80000e66:	8082                	ret

0000000080000e68 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e68:	1141                	add	sp,sp,-16
    80000e6a:	e422                	sd	s0,8(sp)
    80000e6c:	0800                	add	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e6e:	ce11                	beqz	a2,80000e8a <strncmp+0x22>
    80000e70:	00054783          	lbu	a5,0(a0)
    80000e74:	cf89                	beqz	a5,80000e8e <strncmp+0x26>
    80000e76:	0005c703          	lbu	a4,0(a1)
    80000e7a:	00f71a63          	bne	a4,a5,80000e8e <strncmp+0x26>
    n--, p++, q++;
    80000e7e:	367d                	addw	a2,a2,-1
    80000e80:	0505                	add	a0,a0,1
    80000e82:	0585                	add	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e84:	f675                	bnez	a2,80000e70 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e86:	4501                	li	a0,0
    80000e88:	a809                	j	80000e9a <strncmp+0x32>
    80000e8a:	4501                	li	a0,0
    80000e8c:	a039                	j	80000e9a <strncmp+0x32>
  if(n == 0)
    80000e8e:	ca09                	beqz	a2,80000ea0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e90:	00054503          	lbu	a0,0(a0)
    80000e94:	0005c783          	lbu	a5,0(a1)
    80000e98:	9d1d                	subw	a0,a0,a5
}
    80000e9a:	6422                	ld	s0,8(sp)
    80000e9c:	0141                	add	sp,sp,16
    80000e9e:	8082                	ret
    return 0;
    80000ea0:	4501                	li	a0,0
    80000ea2:	bfe5                	j	80000e9a <strncmp+0x32>

0000000080000ea4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000ea4:	1141                	add	sp,sp,-16
    80000ea6:	e422                	sd	s0,8(sp)
    80000ea8:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000eaa:	87aa                	mv	a5,a0
    80000eac:	86b2                	mv	a3,a2
    80000eae:	367d                	addw	a2,a2,-1
    80000eb0:	00d05963          	blez	a3,80000ec2 <strncpy+0x1e>
    80000eb4:	0785                	add	a5,a5,1
    80000eb6:	0005c703          	lbu	a4,0(a1)
    80000eba:	fee78fa3          	sb	a4,-1(a5)
    80000ebe:	0585                	add	a1,a1,1
    80000ec0:	f775                	bnez	a4,80000eac <strncpy+0x8>
    ;
  while(n-- > 0)
    80000ec2:	873e                	mv	a4,a5
    80000ec4:	9fb5                	addw	a5,a5,a3
    80000ec6:	37fd                	addw	a5,a5,-1
    80000ec8:	00c05963          	blez	a2,80000eda <strncpy+0x36>
    *s++ = 0;
    80000ecc:	0705                	add	a4,a4,1
    80000ece:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000ed2:	40e786bb          	subw	a3,a5,a4
    80000ed6:	fed04be3          	bgtz	a3,80000ecc <strncpy+0x28>
  return os;
}
    80000eda:	6422                	ld	s0,8(sp)
    80000edc:	0141                	add	sp,sp,16
    80000ede:	8082                	ret

0000000080000ee0 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000ee0:	1141                	add	sp,sp,-16
    80000ee2:	e422                	sd	s0,8(sp)
    80000ee4:	0800                	add	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000ee6:	02c05363          	blez	a2,80000f0c <safestrcpy+0x2c>
    80000eea:	fff6069b          	addw	a3,a2,-1
    80000eee:	1682                	sll	a3,a3,0x20
    80000ef0:	9281                	srl	a3,a3,0x20
    80000ef2:	96ae                	add	a3,a3,a1
    80000ef4:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000ef6:	00d58963          	beq	a1,a3,80000f08 <safestrcpy+0x28>
    80000efa:	0585                	add	a1,a1,1
    80000efc:	0785                	add	a5,a5,1
    80000efe:	fff5c703          	lbu	a4,-1(a1)
    80000f02:	fee78fa3          	sb	a4,-1(a5)
    80000f06:	fb65                	bnez	a4,80000ef6 <safestrcpy+0x16>
    ;
  *s = 0;
    80000f08:	00078023          	sb	zero,0(a5)
  return os;
}
    80000f0c:	6422                	ld	s0,8(sp)
    80000f0e:	0141                	add	sp,sp,16
    80000f10:	8082                	ret

0000000080000f12 <strlen>:

int
strlen(const char *s)
{
    80000f12:	1141                	add	sp,sp,-16
    80000f14:	e422                	sd	s0,8(sp)
    80000f16:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f18:	00054783          	lbu	a5,0(a0)
    80000f1c:	cf91                	beqz	a5,80000f38 <strlen+0x26>
    80000f1e:	0505                	add	a0,a0,1
    80000f20:	87aa                	mv	a5,a0
    80000f22:	86be                	mv	a3,a5
    80000f24:	0785                	add	a5,a5,1
    80000f26:	fff7c703          	lbu	a4,-1(a5)
    80000f2a:	ff65                	bnez	a4,80000f22 <strlen+0x10>
    80000f2c:	40a6853b          	subw	a0,a3,a0
    80000f30:	2505                	addw	a0,a0,1
    ;
  return n;
}
    80000f32:	6422                	ld	s0,8(sp)
    80000f34:	0141                	add	sp,sp,16
    80000f36:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f38:	4501                	li	a0,0
    80000f3a:	bfe5                	j	80000f32 <strlen+0x20>

0000000080000f3c <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f3c:	1141                	add	sp,sp,-16
    80000f3e:	e406                	sd	ra,8(sp)
    80000f40:	e022                	sd	s0,0(sp)
    80000f42:	0800                	add	s0,sp,16
  if(cpuid() == 0){
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	ad2080e7          	jalr	-1326(ra) # 80001a16 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f4c:	00008717          	auipc	a4,0x8
    80000f50:	99c70713          	add	a4,a4,-1636 # 800088e8 <started>
  if(cpuid() == 0){
    80000f54:	c139                	beqz	a0,80000f9a <main+0x5e>
    while(started == 0)
    80000f56:	431c                	lw	a5,0(a4)
    80000f58:	2781                	sext.w	a5,a5
    80000f5a:	dff5                	beqz	a5,80000f56 <main+0x1a>
      ;
    __sync_synchronize();
    80000f5c:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f60:	00001097          	auipc	ra,0x1
    80000f64:	ab6080e7          	jalr	-1354(ra) # 80001a16 <cpuid>
    80000f68:	85aa                	mv	a1,a0
    80000f6a:	00007517          	auipc	a0,0x7
    80000f6e:	15e50513          	add	a0,a0,350 # 800080c8 <digits+0x88>
    80000f72:	fffff097          	auipc	ra,0xfffff
    80000f76:	614080e7          	jalr	1556(ra) # 80000586 <printf>
    kvminithart();    // turn on paging
    80000f7a:	00000097          	auipc	ra,0x0
    80000f7e:	0d8080e7          	jalr	216(ra) # 80001052 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f82:	00002097          	auipc	ra,0x2
    80000f86:	b20080e7          	jalr	-1248(ra) # 80002aa2 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	1a6080e7          	jalr	422(ra) # 80006130 <plicinithart>
  }

  scheduler();        
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	0a0080e7          	jalr	160(ra) # 80002032 <scheduler>
    consoleinit();
    80000f9a:	fffff097          	auipc	ra,0xfffff
    80000f9e:	4b2080e7          	jalr	1202(ra) # 8000044c <consoleinit>
    printfinit();
    80000fa2:	fffff097          	auipc	ra,0xfffff
    80000fa6:	7c4080e7          	jalr	1988(ra) # 80000766 <printfinit>
    printf("\n");
    80000faa:	00007517          	auipc	a0,0x7
    80000fae:	28e50513          	add	a0,a0,654 # 80008238 <digits+0x1f8>
    80000fb2:	fffff097          	auipc	ra,0xfffff
    80000fb6:	5d4080e7          	jalr	1492(ra) # 80000586 <printf>
    printf("xv6 kernel is booting\n");
    80000fba:	00007517          	auipc	a0,0x7
    80000fbe:	0f650513          	add	a0,a0,246 # 800080b0 <digits+0x70>
    80000fc2:	fffff097          	auipc	ra,0xfffff
    80000fc6:	5c4080e7          	jalr	1476(ra) # 80000586 <printf>
    printf("\n");
    80000fca:	00007517          	auipc	a0,0x7
    80000fce:	26e50513          	add	a0,a0,622 # 80008238 <digits+0x1f8>
    80000fd2:	fffff097          	auipc	ra,0xfffff
    80000fd6:	5b4080e7          	jalr	1460(ra) # 80000586 <printf>
    kinit();         // physical page allocator
    80000fda:	00000097          	auipc	ra,0x0
    80000fde:	b38080e7          	jalr	-1224(ra) # 80000b12 <kinit>
    kvminit();       // create kernel page table
    80000fe2:	00000097          	auipc	ra,0x0
    80000fe6:	310080e7          	jalr	784(ra) # 800012f2 <kvminit>
    kvminithart();   // turn on paging
    80000fea:	00000097          	auipc	ra,0x0
    80000fee:	068080e7          	jalr	104(ra) # 80001052 <kvminithart>
    procinit();      // process table
    80000ff2:	00001097          	auipc	ra,0x1
    80000ff6:	970080e7          	jalr	-1680(ra) # 80001962 <procinit>
    trapinit();      // trap vectors
    80000ffa:	00002097          	auipc	ra,0x2
    80000ffe:	a80080e7          	jalr	-1408(ra) # 80002a7a <trapinit>
    trapinithart();  // install kernel trap vector
    80001002:	00002097          	auipc	ra,0x2
    80001006:	aa0080e7          	jalr	-1376(ra) # 80002aa2 <trapinithart>
    plicinit();      // set up interrupt controller
    8000100a:	00005097          	auipc	ra,0x5
    8000100e:	110080e7          	jalr	272(ra) # 8000611a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001012:	00005097          	auipc	ra,0x5
    80001016:	11e080e7          	jalr	286(ra) # 80006130 <plicinithart>
    binit();         // buffer cache
    8000101a:	00002097          	auipc	ra,0x2
    8000101e:	2f2080e7          	jalr	754(ra) # 8000330c <binit>
    iinit();         // inode table
    80001022:	00003097          	auipc	ra,0x3
    80001026:	990080e7          	jalr	-1648(ra) # 800039b2 <iinit>
    fileinit();      // file table
    8000102a:	00004097          	auipc	ra,0x4
    8000102e:	906080e7          	jalr	-1786(ra) # 80004930 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001032:	00005097          	auipc	ra,0x5
    80001036:	206080e7          	jalr	518(ra) # 80006238 <virtio_disk_init>
    userinit();      // first user process
    8000103a:	00001097          	auipc	ra,0x1
    8000103e:	d08080e7          	jalr	-760(ra) # 80001d42 <userinit>
    __sync_synchronize();
    80001042:	0ff0000f          	fence
    started = 1;
    80001046:	4785                	li	a5,1
    80001048:	00008717          	auipc	a4,0x8
    8000104c:	8af72023          	sw	a5,-1888(a4) # 800088e8 <started>
    80001050:	b789                	j	80000f92 <main+0x56>

0000000080001052 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001052:	1141                	add	sp,sp,-16
    80001054:	e422                	sd	s0,8(sp)
    80001056:	0800                	add	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001058:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    8000105c:	00008797          	auipc	a5,0x8
    80001060:	8947b783          	ld	a5,-1900(a5) # 800088f0 <kernel_pagetable>
    80001064:	83b1                	srl	a5,a5,0xc
    80001066:	577d                	li	a4,-1
    80001068:	177e                	sll	a4,a4,0x3f
    8000106a:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    8000106c:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001070:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80001074:	6422                	ld	s0,8(sp)
    80001076:	0141                	add	sp,sp,16
    80001078:	8082                	ret

000000008000107a <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000107a:	7139                	add	sp,sp,-64
    8000107c:	fc06                	sd	ra,56(sp)
    8000107e:	f822                	sd	s0,48(sp)
    80001080:	f426                	sd	s1,40(sp)
    80001082:	f04a                	sd	s2,32(sp)
    80001084:	ec4e                	sd	s3,24(sp)
    80001086:	e852                	sd	s4,16(sp)
    80001088:	e456                	sd	s5,8(sp)
    8000108a:	e05a                	sd	s6,0(sp)
    8000108c:	0080                	add	s0,sp,64
    8000108e:	84aa                	mv	s1,a0
    80001090:	89ae                	mv	s3,a1
    80001092:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001094:	57fd                	li	a5,-1
    80001096:	83e9                	srl	a5,a5,0x1a
    80001098:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000109a:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000109c:	04b7f263          	bgeu	a5,a1,800010e0 <walk+0x66>
    panic("walk");
    800010a0:	00007517          	auipc	a0,0x7
    800010a4:	04050513          	add	a0,a0,64 # 800080e0 <digits+0xa0>
    800010a8:	fffff097          	auipc	ra,0xfffff
    800010ac:	494080e7          	jalr	1172(ra) # 8000053c <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800010b0:	060a8663          	beqz	s5,8000111c <walk+0xa2>
    800010b4:	00000097          	auipc	ra,0x0
    800010b8:	a9a080e7          	jalr	-1382(ra) # 80000b4e <kalloc>
    800010bc:	84aa                	mv	s1,a0
    800010be:	c529                	beqz	a0,80001108 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800010c0:	6605                	lui	a2,0x1
    800010c2:	4581                	li	a1,0
    800010c4:	00000097          	auipc	ra,0x0
    800010c8:	cd4080e7          	jalr	-812(ra) # 80000d98 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800010cc:	00c4d793          	srl	a5,s1,0xc
    800010d0:	07aa                	sll	a5,a5,0xa
    800010d2:	0017e793          	or	a5,a5,1
    800010d6:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800010da:	3a5d                	addw	s4,s4,-9 # ff7 <_entry-0x7ffff009>
    800010dc:	036a0063          	beq	s4,s6,800010fc <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010e0:	0149d933          	srl	s2,s3,s4
    800010e4:	1ff97913          	and	s2,s2,511
    800010e8:	090e                	sll	s2,s2,0x3
    800010ea:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010ec:	00093483          	ld	s1,0(s2)
    800010f0:	0014f793          	and	a5,s1,1
    800010f4:	dfd5                	beqz	a5,800010b0 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010f6:	80a9                	srl	s1,s1,0xa
    800010f8:	04b2                	sll	s1,s1,0xc
    800010fa:	b7c5                	j	800010da <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010fc:	00c9d513          	srl	a0,s3,0xc
    80001100:	1ff57513          	and	a0,a0,511
    80001104:	050e                	sll	a0,a0,0x3
    80001106:	9526                	add	a0,a0,s1
}
    80001108:	70e2                	ld	ra,56(sp)
    8000110a:	7442                	ld	s0,48(sp)
    8000110c:	74a2                	ld	s1,40(sp)
    8000110e:	7902                	ld	s2,32(sp)
    80001110:	69e2                	ld	s3,24(sp)
    80001112:	6a42                	ld	s4,16(sp)
    80001114:	6aa2                	ld	s5,8(sp)
    80001116:	6b02                	ld	s6,0(sp)
    80001118:	6121                	add	sp,sp,64
    8000111a:	8082                	ret
        return 0;
    8000111c:	4501                	li	a0,0
    8000111e:	b7ed                	j	80001108 <walk+0x8e>

0000000080001120 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001120:	57fd                	li	a5,-1
    80001122:	83e9                	srl	a5,a5,0x1a
    80001124:	00b7f463          	bgeu	a5,a1,8000112c <walkaddr+0xc>
    return 0;
    80001128:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000112a:	8082                	ret
{
    8000112c:	1141                	add	sp,sp,-16
    8000112e:	e406                	sd	ra,8(sp)
    80001130:	e022                	sd	s0,0(sp)
    80001132:	0800                	add	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001134:	4601                	li	a2,0
    80001136:	00000097          	auipc	ra,0x0
    8000113a:	f44080e7          	jalr	-188(ra) # 8000107a <walk>
  if(pte == 0)
    8000113e:	c105                	beqz	a0,8000115e <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001140:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001142:	0117f693          	and	a3,a5,17
    80001146:	4745                	li	a4,17
    return 0;
    80001148:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000114a:	00e68663          	beq	a3,a4,80001156 <walkaddr+0x36>
}
    8000114e:	60a2                	ld	ra,8(sp)
    80001150:	6402                	ld	s0,0(sp)
    80001152:	0141                	add	sp,sp,16
    80001154:	8082                	ret
  pa = PTE2PA(*pte);
    80001156:	83a9                	srl	a5,a5,0xa
    80001158:	00c79513          	sll	a0,a5,0xc
  return pa;
    8000115c:	bfcd                	j	8000114e <walkaddr+0x2e>
    return 0;
    8000115e:	4501                	li	a0,0
    80001160:	b7fd                	j	8000114e <walkaddr+0x2e>

0000000080001162 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001162:	715d                	add	sp,sp,-80
    80001164:	e486                	sd	ra,72(sp)
    80001166:	e0a2                	sd	s0,64(sp)
    80001168:	fc26                	sd	s1,56(sp)
    8000116a:	f84a                	sd	s2,48(sp)
    8000116c:	f44e                	sd	s3,40(sp)
    8000116e:	f052                	sd	s4,32(sp)
    80001170:	ec56                	sd	s5,24(sp)
    80001172:	e85a                	sd	s6,16(sp)
    80001174:	e45e                	sd	s7,8(sp)
    80001176:	0880                	add	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    80001178:	c621                	beqz	a2,800011c0 <mappages+0x5e>
    8000117a:	8aaa                	mv	s5,a0
    8000117c:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    8000117e:	777d                	lui	a4,0xfffff
    80001180:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001184:	fff58993          	add	s3,a1,-1
    80001188:	99b2                	add	s3,s3,a2
    8000118a:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    8000118e:	893e                	mv	s2,a5
    80001190:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V & PTE_W)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001194:	6b85                	lui	s7,0x1
    80001196:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000119a:	4605                	li	a2,1
    8000119c:	85ca                	mv	a1,s2
    8000119e:	8556                	mv	a0,s5
    800011a0:	00000097          	auipc	ra,0x0
    800011a4:	eda080e7          	jalr	-294(ra) # 8000107a <walk>
    800011a8:	c505                	beqz	a0,800011d0 <mappages+0x6e>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011aa:	80b1                	srl	s1,s1,0xc
    800011ac:	04aa                	sll	s1,s1,0xa
    800011ae:	0164e4b3          	or	s1,s1,s6
    800011b2:	0014e493          	or	s1,s1,1
    800011b6:	e104                	sd	s1,0(a0)
    if(a == last)
    800011b8:	03390863          	beq	s2,s3,800011e8 <mappages+0x86>
    a += PGSIZE;
    800011bc:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011be:	bfe1                	j	80001196 <mappages+0x34>
    panic("mappages: size");
    800011c0:	00007517          	auipc	a0,0x7
    800011c4:	f2850513          	add	a0,a0,-216 # 800080e8 <digits+0xa8>
    800011c8:	fffff097          	auipc	ra,0xfffff
    800011cc:	374080e7          	jalr	884(ra) # 8000053c <panic>
      return -1;
    800011d0:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011d2:	60a6                	ld	ra,72(sp)
    800011d4:	6406                	ld	s0,64(sp)
    800011d6:	74e2                	ld	s1,56(sp)
    800011d8:	7942                	ld	s2,48(sp)
    800011da:	79a2                	ld	s3,40(sp)
    800011dc:	7a02                	ld	s4,32(sp)
    800011de:	6ae2                	ld	s5,24(sp)
    800011e0:	6b42                	ld	s6,16(sp)
    800011e2:	6ba2                	ld	s7,8(sp)
    800011e4:	6161                	add	sp,sp,80
    800011e6:	8082                	ret
  return 0;
    800011e8:	4501                	li	a0,0
    800011ea:	b7e5                	j	800011d2 <mappages+0x70>

00000000800011ec <kvmmap>:
{
    800011ec:	1141                	add	sp,sp,-16
    800011ee:	e406                	sd	ra,8(sp)
    800011f0:	e022                	sd	s0,0(sp)
    800011f2:	0800                	add	s0,sp,16
    800011f4:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800011f6:	86b2                	mv	a3,a2
    800011f8:	863e                	mv	a2,a5
    800011fa:	00000097          	auipc	ra,0x0
    800011fe:	f68080e7          	jalr	-152(ra) # 80001162 <mappages>
    80001202:	e509                	bnez	a0,8000120c <kvmmap+0x20>
}
    80001204:	60a2                	ld	ra,8(sp)
    80001206:	6402                	ld	s0,0(sp)
    80001208:	0141                	add	sp,sp,16
    8000120a:	8082                	ret
    panic("kvmmap");
    8000120c:	00007517          	auipc	a0,0x7
    80001210:	eec50513          	add	a0,a0,-276 # 800080f8 <digits+0xb8>
    80001214:	fffff097          	auipc	ra,0xfffff
    80001218:	328080e7          	jalr	808(ra) # 8000053c <panic>

000000008000121c <kvmmake>:
{
    8000121c:	1101                	add	sp,sp,-32
    8000121e:	ec06                	sd	ra,24(sp)
    80001220:	e822                	sd	s0,16(sp)
    80001222:	e426                	sd	s1,8(sp)
    80001224:	e04a                	sd	s2,0(sp)
    80001226:	1000                	add	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001228:	00000097          	auipc	ra,0x0
    8000122c:	926080e7          	jalr	-1754(ra) # 80000b4e <kalloc>
    80001230:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001232:	6605                	lui	a2,0x1
    80001234:	4581                	li	a1,0
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	b62080e7          	jalr	-1182(ra) # 80000d98 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000123e:	4719                	li	a4,6
    80001240:	6685                	lui	a3,0x1
    80001242:	10000637          	lui	a2,0x10000
    80001246:	100005b7          	lui	a1,0x10000
    8000124a:	8526                	mv	a0,s1
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	fa0080e7          	jalr	-96(ra) # 800011ec <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001254:	4719                	li	a4,6
    80001256:	6685                	lui	a3,0x1
    80001258:	10001637          	lui	a2,0x10001
    8000125c:	100015b7          	lui	a1,0x10001
    80001260:	8526                	mv	a0,s1
    80001262:	00000097          	auipc	ra,0x0
    80001266:	f8a080e7          	jalr	-118(ra) # 800011ec <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000126a:	4719                	li	a4,6
    8000126c:	004006b7          	lui	a3,0x400
    80001270:	0c000637          	lui	a2,0xc000
    80001274:	0c0005b7          	lui	a1,0xc000
    80001278:	8526                	mv	a0,s1
    8000127a:	00000097          	auipc	ra,0x0
    8000127e:	f72080e7          	jalr	-142(ra) # 800011ec <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001282:	00007917          	auipc	s2,0x7
    80001286:	d7e90913          	add	s2,s2,-642 # 80008000 <etext>
    8000128a:	4729                	li	a4,10
    8000128c:	80007697          	auipc	a3,0x80007
    80001290:	d7468693          	add	a3,a3,-652 # 8000 <_entry-0x7fff8000>
    80001294:	4605                	li	a2,1
    80001296:	067e                	sll	a2,a2,0x1f
    80001298:	85b2                	mv	a1,a2
    8000129a:	8526                	mv	a0,s1
    8000129c:	00000097          	auipc	ra,0x0
    800012a0:	f50080e7          	jalr	-176(ra) # 800011ec <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012a4:	4719                	li	a4,6
    800012a6:	46c5                	li	a3,17
    800012a8:	06ee                	sll	a3,a3,0x1b
    800012aa:	412686b3          	sub	a3,a3,s2
    800012ae:	864a                	mv	a2,s2
    800012b0:	85ca                	mv	a1,s2
    800012b2:	8526                	mv	a0,s1
    800012b4:	00000097          	auipc	ra,0x0
    800012b8:	f38080e7          	jalr	-200(ra) # 800011ec <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012bc:	4729                	li	a4,10
    800012be:	6685                	lui	a3,0x1
    800012c0:	00006617          	auipc	a2,0x6
    800012c4:	d4060613          	add	a2,a2,-704 # 80007000 <_trampoline>
    800012c8:	040005b7          	lui	a1,0x4000
    800012cc:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    800012ce:	05b2                	sll	a1,a1,0xc
    800012d0:	8526                	mv	a0,s1
    800012d2:	00000097          	auipc	ra,0x0
    800012d6:	f1a080e7          	jalr	-230(ra) # 800011ec <kvmmap>
  proc_mapstacks(kpgtbl);
    800012da:	8526                	mv	a0,s1
    800012dc:	00000097          	auipc	ra,0x0
    800012e0:	5f0080e7          	jalr	1520(ra) # 800018cc <proc_mapstacks>
}
    800012e4:	8526                	mv	a0,s1
    800012e6:	60e2                	ld	ra,24(sp)
    800012e8:	6442                	ld	s0,16(sp)
    800012ea:	64a2                	ld	s1,8(sp)
    800012ec:	6902                	ld	s2,0(sp)
    800012ee:	6105                	add	sp,sp,32
    800012f0:	8082                	ret

00000000800012f2 <kvminit>:
{
    800012f2:	1141                	add	sp,sp,-16
    800012f4:	e406                	sd	ra,8(sp)
    800012f6:	e022                	sd	s0,0(sp)
    800012f8:	0800                	add	s0,sp,16
  kernel_pagetable = kvmmake();
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	f22080e7          	jalr	-222(ra) # 8000121c <kvmmake>
    80001302:	00007797          	auipc	a5,0x7
    80001306:	5ea7b723          	sd	a0,1518(a5) # 800088f0 <kernel_pagetable>
}
    8000130a:	60a2                	ld	ra,8(sp)
    8000130c:	6402                	ld	s0,0(sp)
    8000130e:	0141                	add	sp,sp,16
    80001310:	8082                	ret

0000000080001312 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001312:	715d                	add	sp,sp,-80
    80001314:	e486                	sd	ra,72(sp)
    80001316:	e0a2                	sd	s0,64(sp)
    80001318:	fc26                	sd	s1,56(sp)
    8000131a:	f84a                	sd	s2,48(sp)
    8000131c:	f44e                	sd	s3,40(sp)
    8000131e:	f052                	sd	s4,32(sp)
    80001320:	ec56                	sd	s5,24(sp)
    80001322:	e85a                	sd	s6,16(sp)
    80001324:	e45e                	sd	s7,8(sp)
    80001326:	0880                	add	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001328:	03459793          	sll	a5,a1,0x34
    8000132c:	e795                	bnez	a5,80001358 <uvmunmap+0x46>
    8000132e:	8a2a                	mv	s4,a0
    80001330:	892e                	mv	s2,a1
    80001332:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001334:	0632                	sll	a2,a2,0xc
    80001336:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000133a:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000133c:	6b05                	lui	s6,0x1
    8000133e:	0735e263          	bltu	a1,s3,800013a2 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001342:	60a6                	ld	ra,72(sp)
    80001344:	6406                	ld	s0,64(sp)
    80001346:	74e2                	ld	s1,56(sp)
    80001348:	7942                	ld	s2,48(sp)
    8000134a:	79a2                	ld	s3,40(sp)
    8000134c:	7a02                	ld	s4,32(sp)
    8000134e:	6ae2                	ld	s5,24(sp)
    80001350:	6b42                	ld	s6,16(sp)
    80001352:	6ba2                	ld	s7,8(sp)
    80001354:	6161                	add	sp,sp,80
    80001356:	8082                	ret
    panic("uvmunmap: not aligned");
    80001358:	00007517          	auipc	a0,0x7
    8000135c:	da850513          	add	a0,a0,-600 # 80008100 <digits+0xc0>
    80001360:	fffff097          	auipc	ra,0xfffff
    80001364:	1dc080e7          	jalr	476(ra) # 8000053c <panic>
      panic("uvmunmap: walk");
    80001368:	00007517          	auipc	a0,0x7
    8000136c:	db050513          	add	a0,a0,-592 # 80008118 <digits+0xd8>
    80001370:	fffff097          	auipc	ra,0xfffff
    80001374:	1cc080e7          	jalr	460(ra) # 8000053c <panic>
      panic("uvmunmap: not mapped");
    80001378:	00007517          	auipc	a0,0x7
    8000137c:	db050513          	add	a0,a0,-592 # 80008128 <digits+0xe8>
    80001380:	fffff097          	auipc	ra,0xfffff
    80001384:	1bc080e7          	jalr	444(ra) # 8000053c <panic>
      panic("uvmunmap: not a leaf");
    80001388:	00007517          	auipc	a0,0x7
    8000138c:	db850513          	add	a0,a0,-584 # 80008140 <digits+0x100>
    80001390:	fffff097          	auipc	ra,0xfffff
    80001394:	1ac080e7          	jalr	428(ra) # 8000053c <panic>
    *pte = 0;
    80001398:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000139c:	995a                	add	s2,s2,s6
    8000139e:	fb3972e3          	bgeu	s2,s3,80001342 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013a2:	4601                	li	a2,0
    800013a4:	85ca                	mv	a1,s2
    800013a6:	8552                	mv	a0,s4
    800013a8:	00000097          	auipc	ra,0x0
    800013ac:	cd2080e7          	jalr	-814(ra) # 8000107a <walk>
    800013b0:	84aa                	mv	s1,a0
    800013b2:	d95d                	beqz	a0,80001368 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013b4:	6108                	ld	a0,0(a0)
    800013b6:	00157793          	and	a5,a0,1
    800013ba:	dfdd                	beqz	a5,80001378 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013bc:	3ff57793          	and	a5,a0,1023
    800013c0:	fd7784e3          	beq	a5,s7,80001388 <uvmunmap+0x76>
    if(do_free){
    800013c4:	fc0a8ae3          	beqz	s5,80001398 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800013c8:	8129                	srl	a0,a0,0xa
      kfree((void*)pa);
    800013ca:	0532                	sll	a0,a0,0xc
    800013cc:	fffff097          	auipc	ra,0xfffff
    800013d0:	618080e7          	jalr	1560(ra) # 800009e4 <kfree>
    800013d4:	b7d1                	j	80001398 <uvmunmap+0x86>

00000000800013d6 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013d6:	1101                	add	sp,sp,-32
    800013d8:	ec06                	sd	ra,24(sp)
    800013da:	e822                	sd	s0,16(sp)
    800013dc:	e426                	sd	s1,8(sp)
    800013de:	1000                	add	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013e0:	fffff097          	auipc	ra,0xfffff
    800013e4:	76e080e7          	jalr	1902(ra) # 80000b4e <kalloc>
    800013e8:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013ea:	c519                	beqz	a0,800013f8 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013ec:	6605                	lui	a2,0x1
    800013ee:	4581                	li	a1,0
    800013f0:	00000097          	auipc	ra,0x0
    800013f4:	9a8080e7          	jalr	-1624(ra) # 80000d98 <memset>
  return pagetable;
}
    800013f8:	8526                	mv	a0,s1
    800013fa:	60e2                	ld	ra,24(sp)
    800013fc:	6442                	ld	s0,16(sp)
    800013fe:	64a2                	ld	s1,8(sp)
    80001400:	6105                	add	sp,sp,32
    80001402:	8082                	ret

0000000080001404 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001404:	7179                	add	sp,sp,-48
    80001406:	f406                	sd	ra,40(sp)
    80001408:	f022                	sd	s0,32(sp)
    8000140a:	ec26                	sd	s1,24(sp)
    8000140c:	e84a                	sd	s2,16(sp)
    8000140e:	e44e                	sd	s3,8(sp)
    80001410:	e052                	sd	s4,0(sp)
    80001412:	1800                	add	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001414:	6785                	lui	a5,0x1
    80001416:	04f67863          	bgeu	a2,a5,80001466 <uvmfirst+0x62>
    8000141a:	8a2a                	mv	s4,a0
    8000141c:	89ae                	mv	s3,a1
    8000141e:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001420:	fffff097          	auipc	ra,0xfffff
    80001424:	72e080e7          	jalr	1838(ra) # 80000b4e <kalloc>
    80001428:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000142a:	6605                	lui	a2,0x1
    8000142c:	4581                	li	a1,0
    8000142e:	00000097          	auipc	ra,0x0
    80001432:	96a080e7          	jalr	-1686(ra) # 80000d98 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001436:	4779                	li	a4,30
    80001438:	86ca                	mv	a3,s2
    8000143a:	6605                	lui	a2,0x1
    8000143c:	4581                	li	a1,0
    8000143e:	8552                	mv	a0,s4
    80001440:	00000097          	auipc	ra,0x0
    80001444:	d22080e7          	jalr	-734(ra) # 80001162 <mappages>
  memmove(mem, src, sz);
    80001448:	8626                	mv	a2,s1
    8000144a:	85ce                	mv	a1,s3
    8000144c:	854a                	mv	a0,s2
    8000144e:	00000097          	auipc	ra,0x0
    80001452:	9a6080e7          	jalr	-1626(ra) # 80000df4 <memmove>
}
    80001456:	70a2                	ld	ra,40(sp)
    80001458:	7402                	ld	s0,32(sp)
    8000145a:	64e2                	ld	s1,24(sp)
    8000145c:	6942                	ld	s2,16(sp)
    8000145e:	69a2                	ld	s3,8(sp)
    80001460:	6a02                	ld	s4,0(sp)
    80001462:	6145                	add	sp,sp,48
    80001464:	8082                	ret
    panic("uvmfirst: more than a page");
    80001466:	00007517          	auipc	a0,0x7
    8000146a:	cf250513          	add	a0,a0,-782 # 80008158 <digits+0x118>
    8000146e:	fffff097          	auipc	ra,0xfffff
    80001472:	0ce080e7          	jalr	206(ra) # 8000053c <panic>

0000000080001476 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001476:	1101                	add	sp,sp,-32
    80001478:	ec06                	sd	ra,24(sp)
    8000147a:	e822                	sd	s0,16(sp)
    8000147c:	e426                	sd	s1,8(sp)
    8000147e:	1000                	add	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001480:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001482:	00b67d63          	bgeu	a2,a1,8000149c <uvmdealloc+0x26>
    80001486:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001488:	6785                	lui	a5,0x1
    8000148a:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000148c:	00f60733          	add	a4,a2,a5
    80001490:	76fd                	lui	a3,0xfffff
    80001492:	8f75                	and	a4,a4,a3
    80001494:	97ae                	add	a5,a5,a1
    80001496:	8ff5                	and	a5,a5,a3
    80001498:	00f76863          	bltu	a4,a5,800014a8 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000149c:	8526                	mv	a0,s1
    8000149e:	60e2                	ld	ra,24(sp)
    800014a0:	6442                	ld	s0,16(sp)
    800014a2:	64a2                	ld	s1,8(sp)
    800014a4:	6105                	add	sp,sp,32
    800014a6:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014a8:	8f99                	sub	a5,a5,a4
    800014aa:	83b1                	srl	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014ac:	4685                	li	a3,1
    800014ae:	0007861b          	sext.w	a2,a5
    800014b2:	85ba                	mv	a1,a4
    800014b4:	00000097          	auipc	ra,0x0
    800014b8:	e5e080e7          	jalr	-418(ra) # 80001312 <uvmunmap>
    800014bc:	b7c5                	j	8000149c <uvmdealloc+0x26>

00000000800014be <uvmalloc>:
  if(newsz < oldsz)
    800014be:	0ab66563          	bltu	a2,a1,80001568 <uvmalloc+0xaa>
{
    800014c2:	7139                	add	sp,sp,-64
    800014c4:	fc06                	sd	ra,56(sp)
    800014c6:	f822                	sd	s0,48(sp)
    800014c8:	f426                	sd	s1,40(sp)
    800014ca:	f04a                	sd	s2,32(sp)
    800014cc:	ec4e                	sd	s3,24(sp)
    800014ce:	e852                	sd	s4,16(sp)
    800014d0:	e456                	sd	s5,8(sp)
    800014d2:	e05a                	sd	s6,0(sp)
    800014d4:	0080                	add	s0,sp,64
    800014d6:	8aaa                	mv	s5,a0
    800014d8:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014da:	6785                	lui	a5,0x1
    800014dc:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    800014de:	95be                	add	a1,a1,a5
    800014e0:	77fd                	lui	a5,0xfffff
    800014e2:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014e6:	08c9f363          	bgeu	s3,a2,8000156c <uvmalloc+0xae>
    800014ea:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014ec:	0126eb13          	or	s6,a3,18
    mem = kalloc();
    800014f0:	fffff097          	auipc	ra,0xfffff
    800014f4:	65e080e7          	jalr	1630(ra) # 80000b4e <kalloc>
    800014f8:	84aa                	mv	s1,a0
    if(mem == 0){
    800014fa:	c51d                	beqz	a0,80001528 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    800014fc:	6605                	lui	a2,0x1
    800014fe:	4581                	li	a1,0
    80001500:	00000097          	auipc	ra,0x0
    80001504:	898080e7          	jalr	-1896(ra) # 80000d98 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001508:	875a                	mv	a4,s6
    8000150a:	86a6                	mv	a3,s1
    8000150c:	6605                	lui	a2,0x1
    8000150e:	85ca                	mv	a1,s2
    80001510:	8556                	mv	a0,s5
    80001512:	00000097          	auipc	ra,0x0
    80001516:	c50080e7          	jalr	-944(ra) # 80001162 <mappages>
    8000151a:	e90d                	bnez	a0,8000154c <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000151c:	6785                	lui	a5,0x1
    8000151e:	993e                	add	s2,s2,a5
    80001520:	fd4968e3          	bltu	s2,s4,800014f0 <uvmalloc+0x32>
  return newsz;
    80001524:	8552                	mv	a0,s4
    80001526:	a809                	j	80001538 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001528:	864e                	mv	a2,s3
    8000152a:	85ca                	mv	a1,s2
    8000152c:	8556                	mv	a0,s5
    8000152e:	00000097          	auipc	ra,0x0
    80001532:	f48080e7          	jalr	-184(ra) # 80001476 <uvmdealloc>
      return 0;
    80001536:	4501                	li	a0,0
}
    80001538:	70e2                	ld	ra,56(sp)
    8000153a:	7442                	ld	s0,48(sp)
    8000153c:	74a2                	ld	s1,40(sp)
    8000153e:	7902                	ld	s2,32(sp)
    80001540:	69e2                	ld	s3,24(sp)
    80001542:	6a42                	ld	s4,16(sp)
    80001544:	6aa2                	ld	s5,8(sp)
    80001546:	6b02                	ld	s6,0(sp)
    80001548:	6121                	add	sp,sp,64
    8000154a:	8082                	ret
      kfree(mem);
    8000154c:	8526                	mv	a0,s1
    8000154e:	fffff097          	auipc	ra,0xfffff
    80001552:	496080e7          	jalr	1174(ra) # 800009e4 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001556:	864e                	mv	a2,s3
    80001558:	85ca                	mv	a1,s2
    8000155a:	8556                	mv	a0,s5
    8000155c:	00000097          	auipc	ra,0x0
    80001560:	f1a080e7          	jalr	-230(ra) # 80001476 <uvmdealloc>
      return 0;
    80001564:	4501                	li	a0,0
    80001566:	bfc9                	j	80001538 <uvmalloc+0x7a>
    return oldsz;
    80001568:	852e                	mv	a0,a1
}
    8000156a:	8082                	ret
  return newsz;
    8000156c:	8532                	mv	a0,a2
    8000156e:	b7e9                	j	80001538 <uvmalloc+0x7a>

0000000080001570 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001570:	7179                	add	sp,sp,-48
    80001572:	f406                	sd	ra,40(sp)
    80001574:	f022                	sd	s0,32(sp)
    80001576:	ec26                	sd	s1,24(sp)
    80001578:	e84a                	sd	s2,16(sp)
    8000157a:	e44e                	sd	s3,8(sp)
    8000157c:	e052                	sd	s4,0(sp)
    8000157e:	1800                	add	s0,sp,48
    80001580:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001582:	84aa                	mv	s1,a0
    80001584:	6905                	lui	s2,0x1
    80001586:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001588:	4985                	li	s3,1
    8000158a:	a829                	j	800015a4 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000158c:	83a9                	srl	a5,a5,0xa
      freewalk((pagetable_t)child);
    8000158e:	00c79513          	sll	a0,a5,0xc
    80001592:	00000097          	auipc	ra,0x0
    80001596:	fde080e7          	jalr	-34(ra) # 80001570 <freewalk>
      pagetable[i] = 0;
    8000159a:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000159e:	04a1                	add	s1,s1,8
    800015a0:	03248163          	beq	s1,s2,800015c2 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800015a4:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015a6:	00f7f713          	and	a4,a5,15
    800015aa:	ff3701e3          	beq	a4,s3,8000158c <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015ae:	8b85                	and	a5,a5,1
    800015b0:	d7fd                	beqz	a5,8000159e <freewalk+0x2e>
      panic("freewalk: leaf");
    800015b2:	00007517          	auipc	a0,0x7
    800015b6:	bc650513          	add	a0,a0,-1082 # 80008178 <digits+0x138>
    800015ba:	fffff097          	auipc	ra,0xfffff
    800015be:	f82080e7          	jalr	-126(ra) # 8000053c <panic>
    }
  }
  kfree((void*)pagetable);
    800015c2:	8552                	mv	a0,s4
    800015c4:	fffff097          	auipc	ra,0xfffff
    800015c8:	420080e7          	jalr	1056(ra) # 800009e4 <kfree>
}
    800015cc:	70a2                	ld	ra,40(sp)
    800015ce:	7402                	ld	s0,32(sp)
    800015d0:	64e2                	ld	s1,24(sp)
    800015d2:	6942                	ld	s2,16(sp)
    800015d4:	69a2                	ld	s3,8(sp)
    800015d6:	6a02                	ld	s4,0(sp)
    800015d8:	6145                	add	sp,sp,48
    800015da:	8082                	ret

00000000800015dc <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015dc:	1101                	add	sp,sp,-32
    800015de:	ec06                	sd	ra,24(sp)
    800015e0:	e822                	sd	s0,16(sp)
    800015e2:	e426                	sd	s1,8(sp)
    800015e4:	1000                	add	s0,sp,32
    800015e6:	84aa                	mv	s1,a0
  if(sz > 0)
    800015e8:	e999                	bnez	a1,800015fe <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015ea:	8526                	mv	a0,s1
    800015ec:	00000097          	auipc	ra,0x0
    800015f0:	f84080e7          	jalr	-124(ra) # 80001570 <freewalk>
}
    800015f4:	60e2                	ld	ra,24(sp)
    800015f6:	6442                	ld	s0,16(sp)
    800015f8:	64a2                	ld	s1,8(sp)
    800015fa:	6105                	add	sp,sp,32
    800015fc:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015fe:	6785                	lui	a5,0x1
    80001600:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001602:	95be                	add	a1,a1,a5
    80001604:	4685                	li	a3,1
    80001606:	00c5d613          	srl	a2,a1,0xc
    8000160a:	4581                	li	a1,0
    8000160c:	00000097          	auipc	ra,0x0
    80001610:	d06080e7          	jalr	-762(ra) # 80001312 <uvmunmap>
    80001614:	bfd9                	j	800015ea <uvmfree+0xe>

0000000080001616 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  // char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001616:	ca5d                	beqz	a2,800016cc <uvmcopy+0xb6>
{
    80001618:	7139                	add	sp,sp,-64
    8000161a:	fc06                	sd	ra,56(sp)
    8000161c:	f822                	sd	s0,48(sp)
    8000161e:	f426                	sd	s1,40(sp)
    80001620:	f04a                	sd	s2,32(sp)
    80001622:	ec4e                	sd	s3,24(sp)
    80001624:	e852                	sd	s4,16(sp)
    80001626:	e456                	sd	s5,8(sp)
    80001628:	e05a                	sd	s6,0(sp)
    8000162a:	0080                	add	s0,sp,64
    8000162c:	8b2a                	mv	s6,a0
    8000162e:	8aae                	mv	s5,a1
    80001630:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001632:	4901                	li	s2,0
    if((pte = walk(old, i, 0)) == 0)
    80001634:	4601                	li	a2,0
    80001636:	85ca                	mv	a1,s2
    80001638:	855a                	mv	a0,s6
    8000163a:	00000097          	auipc	ra,0x0
    8000163e:	a40080e7          	jalr	-1472(ra) # 8000107a <walk>
    80001642:	84aa                	mv	s1,a0
    80001644:	c121                	beqz	a0,80001684 <uvmcopy+0x6e>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001646:	611c                	ld	a5,0(a0)
    80001648:	0017f713          	and	a4,a5,1
    8000164c:	c721                	beqz	a4,80001694 <uvmcopy+0x7e>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000164e:	00a7d993          	srl	s3,a5,0xa
    80001652:	09b2                	sll	s3,s3,0xc

    //Disable write on pte
    *pte = *pte & (~PTE_W); 
    80001654:	9bed                	and	a5,a5,-5
    80001656:	e11c                	sd	a5,0(a0)
    add_reference(pa);
    80001658:	854e                	mv	a0,s3
    8000165a:	fffff097          	auipc	ra,0xfffff
    8000165e:	568080e7          	jalr	1384(ra) # 80000bc2 <add_reference>
    flags = PTE_FLAGS(*pte);
    80001662:	6098                	ld	a4,0(s1)
    if(mappages(new, i, PGSIZE, (uint64)pa, flags) != 0){
    80001664:	3ff77713          	and	a4,a4,1023
    80001668:	86ce                	mv	a3,s3
    8000166a:	6605                	lui	a2,0x1
    8000166c:	85ca                	mv	a1,s2
    8000166e:	8556                	mv	a0,s5
    80001670:	00000097          	auipc	ra,0x0
    80001674:	af2080e7          	jalr	-1294(ra) # 80001162 <mappages>
    80001678:	e515                	bnez	a0,800016a4 <uvmcopy+0x8e>
  for(i = 0; i < sz; i += PGSIZE){
    8000167a:	6785                	lui	a5,0x1
    8000167c:	993e                	add	s2,s2,a5
    8000167e:	fb496be3          	bltu	s2,s4,80001634 <uvmcopy+0x1e>
    80001682:	a81d                	j	800016b8 <uvmcopy+0xa2>
      panic("uvmcopy: pte should exist");
    80001684:	00007517          	auipc	a0,0x7
    80001688:	b0450513          	add	a0,a0,-1276 # 80008188 <digits+0x148>
    8000168c:	fffff097          	auipc	ra,0xfffff
    80001690:	eb0080e7          	jalr	-336(ra) # 8000053c <panic>
      panic("uvmcopy: page not present");
    80001694:	00007517          	auipc	a0,0x7
    80001698:	b1450513          	add	a0,a0,-1260 # 800081a8 <digits+0x168>
    8000169c:	fffff097          	auipc	ra,0xfffff
    800016a0:	ea0080e7          	jalr	-352(ra) # 8000053c <panic>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016a4:	4685                	li	a3,1
    800016a6:	00c95613          	srl	a2,s2,0xc
    800016aa:	4581                	li	a1,0
    800016ac:	8556                	mv	a0,s5
    800016ae:	00000097          	auipc	ra,0x0
    800016b2:	c64080e7          	jalr	-924(ra) # 80001312 <uvmunmap>
  return -1;
    800016b6:	557d                	li	a0,-1
}
    800016b8:	70e2                	ld	ra,56(sp)
    800016ba:	7442                	ld	s0,48(sp)
    800016bc:	74a2                	ld	s1,40(sp)
    800016be:	7902                	ld	s2,32(sp)
    800016c0:	69e2                	ld	s3,24(sp)
    800016c2:	6a42                	ld	s4,16(sp)
    800016c4:	6aa2                	ld	s5,8(sp)
    800016c6:	6b02                	ld	s6,0(sp)
    800016c8:	6121                	add	sp,sp,64
    800016ca:	8082                	ret
  return 0;
    800016cc:	4501                	li	a0,0
}
    800016ce:	8082                	ret

00000000800016d0 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016d0:	1141                	add	sp,sp,-16
    800016d2:	e406                	sd	ra,8(sp)
    800016d4:	e022                	sd	s0,0(sp)
    800016d6:	0800                	add	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016d8:	4601                	li	a2,0
    800016da:	00000097          	auipc	ra,0x0
    800016de:	9a0080e7          	jalr	-1632(ra) # 8000107a <walk>
  if(pte == 0)
    800016e2:	c901                	beqz	a0,800016f2 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016e4:	611c                	ld	a5,0(a0)
    800016e6:	9bbd                	and	a5,a5,-17
    800016e8:	e11c                	sd	a5,0(a0)
}
    800016ea:	60a2                	ld	ra,8(sp)
    800016ec:	6402                	ld	s0,0(sp)
    800016ee:	0141                	add	sp,sp,16
    800016f0:	8082                	ret
    panic("uvmclear");
    800016f2:	00007517          	auipc	a0,0x7
    800016f6:	ad650513          	add	a0,a0,-1322 # 800081c8 <digits+0x188>
    800016fa:	fffff097          	auipc	ra,0xfffff
    800016fe:	e42080e7          	jalr	-446(ra) # 8000053c <panic>

0000000080001702 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001702:	c6bd                	beqz	a3,80001770 <copyout+0x6e>
{
    80001704:	715d                	add	sp,sp,-80
    80001706:	e486                	sd	ra,72(sp)
    80001708:	e0a2                	sd	s0,64(sp)
    8000170a:	fc26                	sd	s1,56(sp)
    8000170c:	f84a                	sd	s2,48(sp)
    8000170e:	f44e                	sd	s3,40(sp)
    80001710:	f052                	sd	s4,32(sp)
    80001712:	ec56                	sd	s5,24(sp)
    80001714:	e85a                	sd	s6,16(sp)
    80001716:	e45e                	sd	s7,8(sp)
    80001718:	e062                	sd	s8,0(sp)
    8000171a:	0880                	add	s0,sp,80
    8000171c:	8b2a                	mv	s6,a0
    8000171e:	8c2e                	mv	s8,a1
    80001720:	8a32                	mv	s4,a2
    80001722:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001724:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001726:	6a85                	lui	s5,0x1
    80001728:	a015                	j	8000174c <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000172a:	9562                	add	a0,a0,s8
    8000172c:	0004861b          	sext.w	a2,s1
    80001730:	85d2                	mv	a1,s4
    80001732:	41250533          	sub	a0,a0,s2
    80001736:	fffff097          	auipc	ra,0xfffff
    8000173a:	6be080e7          	jalr	1726(ra) # 80000df4 <memmove>

    len -= n;
    8000173e:	409989b3          	sub	s3,s3,s1
    src += n;
    80001742:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001744:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001748:	02098263          	beqz	s3,8000176c <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000174c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001750:	85ca                	mv	a1,s2
    80001752:	855a                	mv	a0,s6
    80001754:	00000097          	auipc	ra,0x0
    80001758:	9cc080e7          	jalr	-1588(ra) # 80001120 <walkaddr>
    if(pa0 == 0)
    8000175c:	cd01                	beqz	a0,80001774 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000175e:	418904b3          	sub	s1,s2,s8
    80001762:	94d6                	add	s1,s1,s5
    80001764:	fc99f3e3          	bgeu	s3,s1,8000172a <copyout+0x28>
    80001768:	84ce                	mv	s1,s3
    8000176a:	b7c1                	j	8000172a <copyout+0x28>
  }
  return 0;
    8000176c:	4501                	li	a0,0
    8000176e:	a021                	j	80001776 <copyout+0x74>
    80001770:	4501                	li	a0,0
}
    80001772:	8082                	ret
      return -1;
    80001774:	557d                	li	a0,-1
}
    80001776:	60a6                	ld	ra,72(sp)
    80001778:	6406                	ld	s0,64(sp)
    8000177a:	74e2                	ld	s1,56(sp)
    8000177c:	7942                	ld	s2,48(sp)
    8000177e:	79a2                	ld	s3,40(sp)
    80001780:	7a02                	ld	s4,32(sp)
    80001782:	6ae2                	ld	s5,24(sp)
    80001784:	6b42                	ld	s6,16(sp)
    80001786:	6ba2                	ld	s7,8(sp)
    80001788:	6c02                	ld	s8,0(sp)
    8000178a:	6161                	add	sp,sp,80
    8000178c:	8082                	ret

000000008000178e <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000178e:	caa5                	beqz	a3,800017fe <copyin+0x70>
{
    80001790:	715d                	add	sp,sp,-80
    80001792:	e486                	sd	ra,72(sp)
    80001794:	e0a2                	sd	s0,64(sp)
    80001796:	fc26                	sd	s1,56(sp)
    80001798:	f84a                	sd	s2,48(sp)
    8000179a:	f44e                	sd	s3,40(sp)
    8000179c:	f052                	sd	s4,32(sp)
    8000179e:	ec56                	sd	s5,24(sp)
    800017a0:	e85a                	sd	s6,16(sp)
    800017a2:	e45e                	sd	s7,8(sp)
    800017a4:	e062                	sd	s8,0(sp)
    800017a6:	0880                	add	s0,sp,80
    800017a8:	8b2a                	mv	s6,a0
    800017aa:	8a2e                	mv	s4,a1
    800017ac:	8c32                	mv	s8,a2
    800017ae:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017b0:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017b2:	6a85                	lui	s5,0x1
    800017b4:	a01d                	j	800017da <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017b6:	018505b3          	add	a1,a0,s8
    800017ba:	0004861b          	sext.w	a2,s1
    800017be:	412585b3          	sub	a1,a1,s2
    800017c2:	8552                	mv	a0,s4
    800017c4:	fffff097          	auipc	ra,0xfffff
    800017c8:	630080e7          	jalr	1584(ra) # 80000df4 <memmove>

    len -= n;
    800017cc:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017d0:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017d2:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017d6:	02098263          	beqz	s3,800017fa <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    800017da:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	855a                	mv	a0,s6
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	93e080e7          	jalr	-1730(ra) # 80001120 <walkaddr>
    if(pa0 == 0)
    800017ea:	cd01                	beqz	a0,80001802 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800017ec:	418904b3          	sub	s1,s2,s8
    800017f0:	94d6                	add	s1,s1,s5
    800017f2:	fc99f2e3          	bgeu	s3,s1,800017b6 <copyin+0x28>
    800017f6:	84ce                	mv	s1,s3
    800017f8:	bf7d                	j	800017b6 <copyin+0x28>
  }
  return 0;
    800017fa:	4501                	li	a0,0
    800017fc:	a021                	j	80001804 <copyin+0x76>
    800017fe:	4501                	li	a0,0
}
    80001800:	8082                	ret
      return -1;
    80001802:	557d                	li	a0,-1
}
    80001804:	60a6                	ld	ra,72(sp)
    80001806:	6406                	ld	s0,64(sp)
    80001808:	74e2                	ld	s1,56(sp)
    8000180a:	7942                	ld	s2,48(sp)
    8000180c:	79a2                	ld	s3,40(sp)
    8000180e:	7a02                	ld	s4,32(sp)
    80001810:	6ae2                	ld	s5,24(sp)
    80001812:	6b42                	ld	s6,16(sp)
    80001814:	6ba2                	ld	s7,8(sp)
    80001816:	6c02                	ld	s8,0(sp)
    80001818:	6161                	add	sp,sp,80
    8000181a:	8082                	ret

000000008000181c <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000181c:	c2dd                	beqz	a3,800018c2 <copyinstr+0xa6>
{
    8000181e:	715d                	add	sp,sp,-80
    80001820:	e486                	sd	ra,72(sp)
    80001822:	e0a2                	sd	s0,64(sp)
    80001824:	fc26                	sd	s1,56(sp)
    80001826:	f84a                	sd	s2,48(sp)
    80001828:	f44e                	sd	s3,40(sp)
    8000182a:	f052                	sd	s4,32(sp)
    8000182c:	ec56                	sd	s5,24(sp)
    8000182e:	e85a                	sd	s6,16(sp)
    80001830:	e45e                	sd	s7,8(sp)
    80001832:	0880                	add	s0,sp,80
    80001834:	8a2a                	mv	s4,a0
    80001836:	8b2e                	mv	s6,a1
    80001838:	8bb2                	mv	s7,a2
    8000183a:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000183c:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000183e:	6985                	lui	s3,0x1
    80001840:	a02d                	j	8000186a <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001842:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001846:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001848:	37fd                	addw	a5,a5,-1
    8000184a:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000184e:	60a6                	ld	ra,72(sp)
    80001850:	6406                	ld	s0,64(sp)
    80001852:	74e2                	ld	s1,56(sp)
    80001854:	7942                	ld	s2,48(sp)
    80001856:	79a2                	ld	s3,40(sp)
    80001858:	7a02                	ld	s4,32(sp)
    8000185a:	6ae2                	ld	s5,24(sp)
    8000185c:	6b42                	ld	s6,16(sp)
    8000185e:	6ba2                	ld	s7,8(sp)
    80001860:	6161                	add	sp,sp,80
    80001862:	8082                	ret
    srcva = va0 + PGSIZE;
    80001864:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001868:	c8a9                	beqz	s1,800018ba <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    8000186a:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000186e:	85ca                	mv	a1,s2
    80001870:	8552                	mv	a0,s4
    80001872:	00000097          	auipc	ra,0x0
    80001876:	8ae080e7          	jalr	-1874(ra) # 80001120 <walkaddr>
    if(pa0 == 0)
    8000187a:	c131                	beqz	a0,800018be <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    8000187c:	417906b3          	sub	a3,s2,s7
    80001880:	96ce                	add	a3,a3,s3
    80001882:	00d4f363          	bgeu	s1,a3,80001888 <copyinstr+0x6c>
    80001886:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001888:	955e                	add	a0,a0,s7
    8000188a:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000188e:	daf9                	beqz	a3,80001864 <copyinstr+0x48>
    80001890:	87da                	mv	a5,s6
    80001892:	885a                	mv	a6,s6
      if(*p == '\0'){
    80001894:	41650633          	sub	a2,a0,s6
    while(n > 0){
    80001898:	96da                	add	a3,a3,s6
    8000189a:	85be                	mv	a1,a5
      if(*p == '\0'){
    8000189c:	00f60733          	add	a4,a2,a5
    800018a0:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7fdbca80>
    800018a4:	df59                	beqz	a4,80001842 <copyinstr+0x26>
        *dst = *p;
    800018a6:	00e78023          	sb	a4,0(a5)
      dst++;
    800018aa:	0785                	add	a5,a5,1
    while(n > 0){
    800018ac:	fed797e3          	bne	a5,a3,8000189a <copyinstr+0x7e>
    800018b0:	14fd                	add	s1,s1,-1
    800018b2:	94c2                	add	s1,s1,a6
      --max;
    800018b4:	8c8d                	sub	s1,s1,a1
      dst++;
    800018b6:	8b3e                	mv	s6,a5
    800018b8:	b775                	j	80001864 <copyinstr+0x48>
    800018ba:	4781                	li	a5,0
    800018bc:	b771                	j	80001848 <copyinstr+0x2c>
      return -1;
    800018be:	557d                	li	a0,-1
    800018c0:	b779                	j	8000184e <copyinstr+0x32>
  int got_null = 0;
    800018c2:	4781                	li	a5,0
  if(got_null){
    800018c4:	37fd                	addw	a5,a5,-1
    800018c6:	0007851b          	sext.w	a0,a5
}
    800018ca:	8082                	ret

00000000800018cc <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    800018cc:	7139                	add	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	add	s0,sp,64
    800018e0:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800018e2:	0022f497          	auipc	s1,0x22f
    800018e6:	6be48493          	add	s1,s1,1726 # 80230fa0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    800018ea:	8b26                	mv	s6,s1
    800018ec:	00006a97          	auipc	s5,0x6
    800018f0:	714a8a93          	add	s5,s5,1812 # 80008000 <etext>
    800018f4:	04000937          	lui	s2,0x4000
    800018f8:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800018fa:	0932                	sll	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    800018fc:	00236a17          	auipc	s4,0x236
    80001900:	8a4a0a13          	add	s4,s4,-1884 # 802371a0 <tickslock>
    char *pa = kalloc();
    80001904:	fffff097          	auipc	ra,0xfffff
    80001908:	24a080e7          	jalr	586(ra) # 80000b4e <kalloc>
    8000190c:	862a                	mv	a2,a0
    if (pa == 0)
    8000190e:	c131                	beqz	a0,80001952 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001910:	416485b3          	sub	a1,s1,s6
    80001914:	858d                	sra	a1,a1,0x3
    80001916:	000ab783          	ld	a5,0(s5)
    8000191a:	02f585b3          	mul	a1,a1,a5
    8000191e:	2585                	addw	a1,a1,1
    80001920:	00d5959b          	sllw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001924:	4719                	li	a4,6
    80001926:	6685                	lui	a3,0x1
    80001928:	40b905b3          	sub	a1,s2,a1
    8000192c:	854e                	mv	a0,s3
    8000192e:	00000097          	auipc	ra,0x0
    80001932:	8be080e7          	jalr	-1858(ra) # 800011ec <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001936:	18848493          	add	s1,s1,392
    8000193a:	fd4495e3          	bne	s1,s4,80001904 <proc_mapstacks+0x38>
  }
}
    8000193e:	70e2                	ld	ra,56(sp)
    80001940:	7442                	ld	s0,48(sp)
    80001942:	74a2                	ld	s1,40(sp)
    80001944:	7902                	ld	s2,32(sp)
    80001946:	69e2                	ld	s3,24(sp)
    80001948:	6a42                	ld	s4,16(sp)
    8000194a:	6aa2                	ld	s5,8(sp)
    8000194c:	6b02                	ld	s6,0(sp)
    8000194e:	6121                	add	sp,sp,64
    80001950:	8082                	ret
      panic("kalloc");
    80001952:	00007517          	auipc	a0,0x7
    80001956:	88650513          	add	a0,a0,-1914 # 800081d8 <digits+0x198>
    8000195a:	fffff097          	auipc	ra,0xfffff
    8000195e:	be2080e7          	jalr	-1054(ra) # 8000053c <panic>

0000000080001962 <procinit>:

// initialize the proc table.
void procinit(void)
{
    80001962:	7139                	add	sp,sp,-64
    80001964:	fc06                	sd	ra,56(sp)
    80001966:	f822                	sd	s0,48(sp)
    80001968:	f426                	sd	s1,40(sp)
    8000196a:	f04a                	sd	s2,32(sp)
    8000196c:	ec4e                	sd	s3,24(sp)
    8000196e:	e852                	sd	s4,16(sp)
    80001970:	e456                	sd	s5,8(sp)
    80001972:	e05a                	sd	s6,0(sp)
    80001974:	0080                	add	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001976:	00007597          	auipc	a1,0x7
    8000197a:	86a58593          	add	a1,a1,-1942 # 800081e0 <digits+0x1a0>
    8000197e:	0022f517          	auipc	a0,0x22f
    80001982:	1f250513          	add	a0,a0,498 # 80230b70 <pid_lock>
    80001986:	fffff097          	auipc	ra,0xfffff
    8000198a:	286080e7          	jalr	646(ra) # 80000c0c <initlock>
  initlock(&wait_lock, "wait_lock");
    8000198e:	00007597          	auipc	a1,0x7
    80001992:	85a58593          	add	a1,a1,-1958 # 800081e8 <digits+0x1a8>
    80001996:	0022f517          	auipc	a0,0x22f
    8000199a:	1f250513          	add	a0,a0,498 # 80230b88 <wait_lock>
    8000199e:	fffff097          	auipc	ra,0xfffff
    800019a2:	26e080e7          	jalr	622(ra) # 80000c0c <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    800019a6:	0022f497          	auipc	s1,0x22f
    800019aa:	5fa48493          	add	s1,s1,1530 # 80230fa0 <proc>
  {
    initlock(&p->lock, "proc");
    800019ae:	00007b17          	auipc	s6,0x7
    800019b2:	84ab0b13          	add	s6,s6,-1974 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    800019b6:	8aa6                	mv	s5,s1
    800019b8:	00006a17          	auipc	s4,0x6
    800019bc:	648a0a13          	add	s4,s4,1608 # 80008000 <etext>
    800019c0:	04000937          	lui	s2,0x4000
    800019c4:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800019c6:	0932                	sll	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    800019c8:	00235997          	auipc	s3,0x235
    800019cc:	7d898993          	add	s3,s3,2008 # 802371a0 <tickslock>
    initlock(&p->lock, "proc");
    800019d0:	85da                	mv	a1,s6
    800019d2:	8526                	mv	a0,s1
    800019d4:	fffff097          	auipc	ra,0xfffff
    800019d8:	238080e7          	jalr	568(ra) # 80000c0c <initlock>
    p->state = UNUSED;
    800019dc:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    800019e0:	415487b3          	sub	a5,s1,s5
    800019e4:	878d                	sra	a5,a5,0x3
    800019e6:	000a3703          	ld	a4,0(s4)
    800019ea:	02e787b3          	mul	a5,a5,a4
    800019ee:	2785                	addw	a5,a5,1
    800019f0:	00d7979b          	sllw	a5,a5,0xd
    800019f4:	40f907b3          	sub	a5,s2,a5
    800019f8:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    800019fa:	18848493          	add	s1,s1,392
    800019fe:	fd3499e3          	bne	s1,s3,800019d0 <procinit+0x6e>
  }
}
    80001a02:	70e2                	ld	ra,56(sp)
    80001a04:	7442                	ld	s0,48(sp)
    80001a06:	74a2                	ld	s1,40(sp)
    80001a08:	7902                	ld	s2,32(sp)
    80001a0a:	69e2                	ld	s3,24(sp)
    80001a0c:	6a42                	ld	s4,16(sp)
    80001a0e:	6aa2                	ld	s5,8(sp)
    80001a10:	6b02                	ld	s6,0(sp)
    80001a12:	6121                	add	sp,sp,64
    80001a14:	8082                	ret

0000000080001a16 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001a16:	1141                	add	sp,sp,-16
    80001a18:	e422                	sd	s0,8(sp)
    80001a1a:	0800                	add	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a1c:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a1e:	2501                	sext.w	a0,a0
    80001a20:	6422                	ld	s0,8(sp)
    80001a22:	0141                	add	sp,sp,16
    80001a24:	8082                	ret

0000000080001a26 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001a26:	1141                	add	sp,sp,-16
    80001a28:	e422                	sd	s0,8(sp)
    80001a2a:	0800                	add	s0,sp,16
    80001a2c:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a2e:	2781                	sext.w	a5,a5
    80001a30:	079e                	sll	a5,a5,0x7
  return c;
}
    80001a32:	0022f517          	auipc	a0,0x22f
    80001a36:	16e50513          	add	a0,a0,366 # 80230ba0 <cpus>
    80001a3a:	953e                	add	a0,a0,a5
    80001a3c:	6422                	ld	s0,8(sp)
    80001a3e:	0141                	add	sp,sp,16
    80001a40:	8082                	ret

0000000080001a42 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001a42:	1101                	add	sp,sp,-32
    80001a44:	ec06                	sd	ra,24(sp)
    80001a46:	e822                	sd	s0,16(sp)
    80001a48:	e426                	sd	s1,8(sp)
    80001a4a:	1000                	add	s0,sp,32
  push_off();
    80001a4c:	fffff097          	auipc	ra,0xfffff
    80001a50:	204080e7          	jalr	516(ra) # 80000c50 <push_off>
    80001a54:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a56:	2781                	sext.w	a5,a5
    80001a58:	079e                	sll	a5,a5,0x7
    80001a5a:	0022f717          	auipc	a4,0x22f
    80001a5e:	11670713          	add	a4,a4,278 # 80230b70 <pid_lock>
    80001a62:	97ba                	add	a5,a5,a4
    80001a64:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a66:	fffff097          	auipc	ra,0xfffff
    80001a6a:	28a080e7          	jalr	650(ra) # 80000cf0 <pop_off>
  return p;
}
    80001a6e:	8526                	mv	a0,s1
    80001a70:	60e2                	ld	ra,24(sp)
    80001a72:	6442                	ld	s0,16(sp)
    80001a74:	64a2                	ld	s1,8(sp)
    80001a76:	6105                	add	sp,sp,32
    80001a78:	8082                	ret

0000000080001a7a <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001a7a:	1141                	add	sp,sp,-16
    80001a7c:	e406                	sd	ra,8(sp)
    80001a7e:	e022                	sd	s0,0(sp)
    80001a80:	0800                	add	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a82:	00000097          	auipc	ra,0x0
    80001a86:	fc0080e7          	jalr	-64(ra) # 80001a42 <myproc>
    80001a8a:	fffff097          	auipc	ra,0xfffff
    80001a8e:	2c6080e7          	jalr	710(ra) # 80000d50 <release>

  if (first)
    80001a92:	00007797          	auipc	a5,0x7
    80001a96:	dee7a783          	lw	a5,-530(a5) # 80008880 <first.1>
    80001a9a:	eb89                	bnez	a5,80001aac <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a9c:	00001097          	auipc	ra,0x1
    80001aa0:	01e080e7          	jalr	30(ra) # 80002aba <usertrapret>
}
    80001aa4:	60a2                	ld	ra,8(sp)
    80001aa6:	6402                	ld	s0,0(sp)
    80001aa8:	0141                	add	sp,sp,16
    80001aaa:	8082                	ret
    first = 0;
    80001aac:	00007797          	auipc	a5,0x7
    80001ab0:	dc07aa23          	sw	zero,-556(a5) # 80008880 <first.1>
    fsinit(ROOTDEV);
    80001ab4:	4505                	li	a0,1
    80001ab6:	00002097          	auipc	ra,0x2
    80001aba:	e7c080e7          	jalr	-388(ra) # 80003932 <fsinit>
    80001abe:	bff9                	j	80001a9c <forkret+0x22>

0000000080001ac0 <allocpid>:
{
    80001ac0:	1101                	add	sp,sp,-32
    80001ac2:	ec06                	sd	ra,24(sp)
    80001ac4:	e822                	sd	s0,16(sp)
    80001ac6:	e426                	sd	s1,8(sp)
    80001ac8:	e04a                	sd	s2,0(sp)
    80001aca:	1000                	add	s0,sp,32
  acquire(&pid_lock);
    80001acc:	0022f917          	auipc	s2,0x22f
    80001ad0:	0a490913          	add	s2,s2,164 # 80230b70 <pid_lock>
    80001ad4:	854a                	mv	a0,s2
    80001ad6:	fffff097          	auipc	ra,0xfffff
    80001ada:	1c6080e7          	jalr	454(ra) # 80000c9c <acquire>
  pid = nextpid;
    80001ade:	00007797          	auipc	a5,0x7
    80001ae2:	da678793          	add	a5,a5,-602 # 80008884 <nextpid>
    80001ae6:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ae8:	0014871b          	addw	a4,s1,1
    80001aec:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001aee:	854a                	mv	a0,s2
    80001af0:	fffff097          	auipc	ra,0xfffff
    80001af4:	260080e7          	jalr	608(ra) # 80000d50 <release>
}
    80001af8:	8526                	mv	a0,s1
    80001afa:	60e2                	ld	ra,24(sp)
    80001afc:	6442                	ld	s0,16(sp)
    80001afe:	64a2                	ld	s1,8(sp)
    80001b00:	6902                	ld	s2,0(sp)
    80001b02:	6105                	add	sp,sp,32
    80001b04:	8082                	ret

0000000080001b06 <proc_pagetable>:
{
    80001b06:	1101                	add	sp,sp,-32
    80001b08:	ec06                	sd	ra,24(sp)
    80001b0a:	e822                	sd	s0,16(sp)
    80001b0c:	e426                	sd	s1,8(sp)
    80001b0e:	e04a                	sd	s2,0(sp)
    80001b10:	1000                	add	s0,sp,32
    80001b12:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b14:	00000097          	auipc	ra,0x0
    80001b18:	8c2080e7          	jalr	-1854(ra) # 800013d6 <uvmcreate>
    80001b1c:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001b1e:	c121                	beqz	a0,80001b5e <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b20:	4729                	li	a4,10
    80001b22:	00005697          	auipc	a3,0x5
    80001b26:	4de68693          	add	a3,a3,1246 # 80007000 <_trampoline>
    80001b2a:	6605                	lui	a2,0x1
    80001b2c:	040005b7          	lui	a1,0x4000
    80001b30:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b32:	05b2                	sll	a1,a1,0xc
    80001b34:	fffff097          	auipc	ra,0xfffff
    80001b38:	62e080e7          	jalr	1582(ra) # 80001162 <mappages>
    80001b3c:	02054863          	bltz	a0,80001b6c <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b40:	4719                	li	a4,6
    80001b42:	05893683          	ld	a3,88(s2)
    80001b46:	6605                	lui	a2,0x1
    80001b48:	020005b7          	lui	a1,0x2000
    80001b4c:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b4e:	05b6                	sll	a1,a1,0xd
    80001b50:	8526                	mv	a0,s1
    80001b52:	fffff097          	auipc	ra,0xfffff
    80001b56:	610080e7          	jalr	1552(ra) # 80001162 <mappages>
    80001b5a:	02054163          	bltz	a0,80001b7c <proc_pagetable+0x76>
}
    80001b5e:	8526                	mv	a0,s1
    80001b60:	60e2                	ld	ra,24(sp)
    80001b62:	6442                	ld	s0,16(sp)
    80001b64:	64a2                	ld	s1,8(sp)
    80001b66:	6902                	ld	s2,0(sp)
    80001b68:	6105                	add	sp,sp,32
    80001b6a:	8082                	ret
    uvmfree(pagetable, 0);
    80001b6c:	4581                	li	a1,0
    80001b6e:	8526                	mv	a0,s1
    80001b70:	00000097          	auipc	ra,0x0
    80001b74:	a6c080e7          	jalr	-1428(ra) # 800015dc <uvmfree>
    return 0;
    80001b78:	4481                	li	s1,0
    80001b7a:	b7d5                	j	80001b5e <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b7c:	4681                	li	a3,0
    80001b7e:	4605                	li	a2,1
    80001b80:	040005b7          	lui	a1,0x4000
    80001b84:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b86:	05b2                	sll	a1,a1,0xc
    80001b88:	8526                	mv	a0,s1
    80001b8a:	fffff097          	auipc	ra,0xfffff
    80001b8e:	788080e7          	jalr	1928(ra) # 80001312 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b92:	4581                	li	a1,0
    80001b94:	8526                	mv	a0,s1
    80001b96:	00000097          	auipc	ra,0x0
    80001b9a:	a46080e7          	jalr	-1466(ra) # 800015dc <uvmfree>
    return 0;
    80001b9e:	4481                	li	s1,0
    80001ba0:	bf7d                	j	80001b5e <proc_pagetable+0x58>

0000000080001ba2 <proc_freepagetable>:
{
    80001ba2:	1101                	add	sp,sp,-32
    80001ba4:	ec06                	sd	ra,24(sp)
    80001ba6:	e822                	sd	s0,16(sp)
    80001ba8:	e426                	sd	s1,8(sp)
    80001baa:	e04a                	sd	s2,0(sp)
    80001bac:	1000                	add	s0,sp,32
    80001bae:	84aa                	mv	s1,a0
    80001bb0:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bb2:	4681                	li	a3,0
    80001bb4:	4605                	li	a2,1
    80001bb6:	040005b7          	lui	a1,0x4000
    80001bba:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001bbc:	05b2                	sll	a1,a1,0xc
    80001bbe:	fffff097          	auipc	ra,0xfffff
    80001bc2:	754080e7          	jalr	1876(ra) # 80001312 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bc6:	4681                	li	a3,0
    80001bc8:	4605                	li	a2,1
    80001bca:	020005b7          	lui	a1,0x2000
    80001bce:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001bd0:	05b6                	sll	a1,a1,0xd
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	73e080e7          	jalr	1854(ra) # 80001312 <uvmunmap>
  uvmfree(pagetable, sz);
    80001bdc:	85ca                	mv	a1,s2
    80001bde:	8526                	mv	a0,s1
    80001be0:	00000097          	auipc	ra,0x0
    80001be4:	9fc080e7          	jalr	-1540(ra) # 800015dc <uvmfree>
}
    80001be8:	60e2                	ld	ra,24(sp)
    80001bea:	6442                	ld	s0,16(sp)
    80001bec:	64a2                	ld	s1,8(sp)
    80001bee:	6902                	ld	s2,0(sp)
    80001bf0:	6105                	add	sp,sp,32
    80001bf2:	8082                	ret

0000000080001bf4 <freeproc>:
{
    80001bf4:	1101                	add	sp,sp,-32
    80001bf6:	ec06                	sd	ra,24(sp)
    80001bf8:	e822                	sd	s0,16(sp)
    80001bfa:	e426                	sd	s1,8(sp)
    80001bfc:	1000                	add	s0,sp,32
    80001bfe:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001c00:	6d28                	ld	a0,88(a0)
    80001c02:	c509                	beqz	a0,80001c0c <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	de0080e7          	jalr	-544(ra) # 800009e4 <kfree>
  p->trapframe = 0;
    80001c0c:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001c10:	68a8                	ld	a0,80(s1)
    80001c12:	c511                	beqz	a0,80001c1e <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c14:	64ac                	ld	a1,72(s1)
    80001c16:	00000097          	auipc	ra,0x0
    80001c1a:	f8c080e7          	jalr	-116(ra) # 80001ba2 <proc_freepagetable>
  p->pagetable = 0;
    80001c1e:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c22:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c26:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c2a:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c2e:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c32:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c36:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c3a:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c3e:	0004ac23          	sw	zero,24(s1)
}
    80001c42:	60e2                	ld	ra,24(sp)
    80001c44:	6442                	ld	s0,16(sp)
    80001c46:	64a2                	ld	s1,8(sp)
    80001c48:	6105                	add	sp,sp,32
    80001c4a:	8082                	ret

0000000080001c4c <allocproc>:
{
    80001c4c:	1101                	add	sp,sp,-32
    80001c4e:	ec06                	sd	ra,24(sp)
    80001c50:	e822                	sd	s0,16(sp)
    80001c52:	e426                	sd	s1,8(sp)
    80001c54:	e04a                	sd	s2,0(sp)
    80001c56:	1000                	add	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001c58:	0022f497          	auipc	s1,0x22f
    80001c5c:	34848493          	add	s1,s1,840 # 80230fa0 <proc>
    80001c60:	00235917          	auipc	s2,0x235
    80001c64:	54090913          	add	s2,s2,1344 # 802371a0 <tickslock>
    acquire(&p->lock);
    80001c68:	8526                	mv	a0,s1
    80001c6a:	fffff097          	auipc	ra,0xfffff
    80001c6e:	032080e7          	jalr	50(ra) # 80000c9c <acquire>
    if (p->state == UNUSED)
    80001c72:	4c9c                	lw	a5,24(s1)
    80001c74:	cf81                	beqz	a5,80001c8c <allocproc+0x40>
      release(&p->lock);
    80001c76:	8526                	mv	a0,s1
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	0d8080e7          	jalr	216(ra) # 80000d50 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001c80:	18848493          	add	s1,s1,392
    80001c84:	ff2492e3          	bne	s1,s2,80001c68 <allocproc+0x1c>
  return 0;
    80001c88:	4481                	li	s1,0
    80001c8a:	a8ad                	j	80001d04 <allocproc+0xb8>
  p->pid = allocpid();
    80001c8c:	00000097          	auipc	ra,0x0
    80001c90:	e34080e7          	jalr	-460(ra) # 80001ac0 <allocpid>
    80001c94:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c96:	4785                	li	a5,1
    80001c98:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c9a:	fffff097          	auipc	ra,0xfffff
    80001c9e:	eb4080e7          	jalr	-332(ra) # 80000b4e <kalloc>
    80001ca2:	892a                	mv	s2,a0
    80001ca4:	eca8                	sd	a0,88(s1)
    80001ca6:	c535                	beqz	a0,80001d12 <allocproc+0xc6>
  p->pagetable = proc_pagetable(p);
    80001ca8:	8526                	mv	a0,s1
    80001caa:	00000097          	auipc	ra,0x0
    80001cae:	e5c080e7          	jalr	-420(ra) # 80001b06 <proc_pagetable>
    80001cb2:	892a                	mv	s2,a0
    80001cb4:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001cb6:	c935                	beqz	a0,80001d2a <allocproc+0xde>
  memset(&p->context, 0, sizeof(p->context));
    80001cb8:	07000613          	li	a2,112
    80001cbc:	4581                	li	a1,0
    80001cbe:	06048513          	add	a0,s1,96
    80001cc2:	fffff097          	auipc	ra,0xfffff
    80001cc6:	0d6080e7          	jalr	214(ra) # 80000d98 <memset>
  p->context.ra = (uint64)forkret;
    80001cca:	00000797          	auipc	a5,0x0
    80001cce:	db078793          	add	a5,a5,-592 # 80001a7a <forkret>
    80001cd2:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cd4:	60bc                	ld	a5,64(s1)
    80001cd6:	6705                	lui	a4,0x1
    80001cd8:	97ba                	add	a5,a5,a4
    80001cda:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001cdc:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001ce0:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001ce4:	00007797          	auipc	a5,0x7
    80001ce8:	c1c7a783          	lw	a5,-996(a5) # 80008900 <ticks>
    80001cec:	16f4a623          	sw	a5,364(s1)
    p->RTime = 0;
    80001cf0:	1604aa23          	sw	zero,372(s1)
    p->STime = 0;
    80001cf4:	1604ac23          	sw	zero,376(s1)
    p->WTime = 0;
    80001cf8:	1604ae23          	sw	zero,380(s1)
    p->SP = 50;
    80001cfc:	03200793          	li	a5,50
    80001d00:	18f4a023          	sw	a5,384(s1)
}
    80001d04:	8526                	mv	a0,s1
    80001d06:	60e2                	ld	ra,24(sp)
    80001d08:	6442                	ld	s0,16(sp)
    80001d0a:	64a2                	ld	s1,8(sp)
    80001d0c:	6902                	ld	s2,0(sp)
    80001d0e:	6105                	add	sp,sp,32
    80001d10:	8082                	ret
    freeproc(p);
    80001d12:	8526                	mv	a0,s1
    80001d14:	00000097          	auipc	ra,0x0
    80001d18:	ee0080e7          	jalr	-288(ra) # 80001bf4 <freeproc>
    release(&p->lock);
    80001d1c:	8526                	mv	a0,s1
    80001d1e:	fffff097          	auipc	ra,0xfffff
    80001d22:	032080e7          	jalr	50(ra) # 80000d50 <release>
    return 0;
    80001d26:	84ca                	mv	s1,s2
    80001d28:	bff1                	j	80001d04 <allocproc+0xb8>
    freeproc(p);
    80001d2a:	8526                	mv	a0,s1
    80001d2c:	00000097          	auipc	ra,0x0
    80001d30:	ec8080e7          	jalr	-312(ra) # 80001bf4 <freeproc>
    release(&p->lock);
    80001d34:	8526                	mv	a0,s1
    80001d36:	fffff097          	auipc	ra,0xfffff
    80001d3a:	01a080e7          	jalr	26(ra) # 80000d50 <release>
    return 0;
    80001d3e:	84ca                	mv	s1,s2
    80001d40:	b7d1                	j	80001d04 <allocproc+0xb8>

0000000080001d42 <userinit>:
{
    80001d42:	1101                	add	sp,sp,-32
    80001d44:	ec06                	sd	ra,24(sp)
    80001d46:	e822                	sd	s0,16(sp)
    80001d48:	e426                	sd	s1,8(sp)
    80001d4a:	1000                	add	s0,sp,32
  p = allocproc();
    80001d4c:	00000097          	auipc	ra,0x0
    80001d50:	f00080e7          	jalr	-256(ra) # 80001c4c <allocproc>
    80001d54:	84aa                	mv	s1,a0
  initproc = p;
    80001d56:	00007797          	auipc	a5,0x7
    80001d5a:	baa7b123          	sd	a0,-1118(a5) # 800088f8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001d5e:	03400613          	li	a2,52
    80001d62:	00007597          	auipc	a1,0x7
    80001d66:	b2e58593          	add	a1,a1,-1234 # 80008890 <initcode>
    80001d6a:	6928                	ld	a0,80(a0)
    80001d6c:	fffff097          	auipc	ra,0xfffff
    80001d70:	698080e7          	jalr	1688(ra) # 80001404 <uvmfirst>
  p->sz = PGSIZE;
    80001d74:	6785                	lui	a5,0x1
    80001d76:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001d78:	6cb8                	ld	a4,88(s1)
    80001d7a:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001d7e:	6cb8                	ld	a4,88(s1)
    80001d80:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d82:	4641                	li	a2,16
    80001d84:	00006597          	auipc	a1,0x6
    80001d88:	47c58593          	add	a1,a1,1148 # 80008200 <digits+0x1c0>
    80001d8c:	15848513          	add	a0,s1,344
    80001d90:	fffff097          	auipc	ra,0xfffff
    80001d94:	150080e7          	jalr	336(ra) # 80000ee0 <safestrcpy>
  p->cwd = namei("/");
    80001d98:	00006517          	auipc	a0,0x6
    80001d9c:	47850513          	add	a0,a0,1144 # 80008210 <digits+0x1d0>
    80001da0:	00002097          	auipc	ra,0x2
    80001da4:	5b0080e7          	jalr	1456(ra) # 80004350 <namei>
    80001da8:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001dac:	478d                	li	a5,3
    80001dae:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001db0:	8526                	mv	a0,s1
    80001db2:	fffff097          	auipc	ra,0xfffff
    80001db6:	f9e080e7          	jalr	-98(ra) # 80000d50 <release>
}
    80001dba:	60e2                	ld	ra,24(sp)
    80001dbc:	6442                	ld	s0,16(sp)
    80001dbe:	64a2                	ld	s1,8(sp)
    80001dc0:	6105                	add	sp,sp,32
    80001dc2:	8082                	ret

0000000080001dc4 <growproc>:
{
    80001dc4:	1101                	add	sp,sp,-32
    80001dc6:	ec06                	sd	ra,24(sp)
    80001dc8:	e822                	sd	s0,16(sp)
    80001dca:	e426                	sd	s1,8(sp)
    80001dcc:	e04a                	sd	s2,0(sp)
    80001dce:	1000                	add	s0,sp,32
    80001dd0:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001dd2:	00000097          	auipc	ra,0x0
    80001dd6:	c70080e7          	jalr	-912(ra) # 80001a42 <myproc>
    80001dda:	84aa                	mv	s1,a0
  sz = p->sz;
    80001ddc:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001dde:	01204c63          	bgtz	s2,80001df6 <growproc+0x32>
  else if (n < 0)
    80001de2:	02094663          	bltz	s2,80001e0e <growproc+0x4a>
  p->sz = sz;
    80001de6:	e4ac                	sd	a1,72(s1)
  return 0;
    80001de8:	4501                	li	a0,0
}
    80001dea:	60e2                	ld	ra,24(sp)
    80001dec:	6442                	ld	s0,16(sp)
    80001dee:	64a2                	ld	s1,8(sp)
    80001df0:	6902                	ld	s2,0(sp)
    80001df2:	6105                	add	sp,sp,32
    80001df4:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001df6:	4691                	li	a3,4
    80001df8:	00b90633          	add	a2,s2,a1
    80001dfc:	6928                	ld	a0,80(a0)
    80001dfe:	fffff097          	auipc	ra,0xfffff
    80001e02:	6c0080e7          	jalr	1728(ra) # 800014be <uvmalloc>
    80001e06:	85aa                	mv	a1,a0
    80001e08:	fd79                	bnez	a0,80001de6 <growproc+0x22>
      return -1;
    80001e0a:	557d                	li	a0,-1
    80001e0c:	bff9                	j	80001dea <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e0e:	00b90633          	add	a2,s2,a1
    80001e12:	6928                	ld	a0,80(a0)
    80001e14:	fffff097          	auipc	ra,0xfffff
    80001e18:	662080e7          	jalr	1634(ra) # 80001476 <uvmdealloc>
    80001e1c:	85aa                	mv	a1,a0
    80001e1e:	b7e1                	j	80001de6 <growproc+0x22>

0000000080001e20 <fork>:
{
    80001e20:	7139                	add	sp,sp,-64
    80001e22:	fc06                	sd	ra,56(sp)
    80001e24:	f822                	sd	s0,48(sp)
    80001e26:	f426                	sd	s1,40(sp)
    80001e28:	f04a                	sd	s2,32(sp)
    80001e2a:	ec4e                	sd	s3,24(sp)
    80001e2c:	e852                	sd	s4,16(sp)
    80001e2e:	e456                	sd	s5,8(sp)
    80001e30:	0080                	add	s0,sp,64
  struct proc *p = myproc();
    80001e32:	00000097          	auipc	ra,0x0
    80001e36:	c10080e7          	jalr	-1008(ra) # 80001a42 <myproc>
    80001e3a:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001e3c:	00000097          	auipc	ra,0x0
    80001e40:	e10080e7          	jalr	-496(ra) # 80001c4c <allocproc>
    80001e44:	10050c63          	beqz	a0,80001f5c <fork+0x13c>
    80001e48:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001e4a:	048ab603          	ld	a2,72(s5)
    80001e4e:	692c                	ld	a1,80(a0)
    80001e50:	050ab503          	ld	a0,80(s5)
    80001e54:	fffff097          	auipc	ra,0xfffff
    80001e58:	7c2080e7          	jalr	1986(ra) # 80001616 <uvmcopy>
    80001e5c:	04054863          	bltz	a0,80001eac <fork+0x8c>
  np->sz = p->sz;
    80001e60:	048ab783          	ld	a5,72(s5)
    80001e64:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e68:	058ab683          	ld	a3,88(s5)
    80001e6c:	87b6                	mv	a5,a3
    80001e6e:	058a3703          	ld	a4,88(s4)
    80001e72:	12068693          	add	a3,a3,288
    80001e76:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e7a:	6788                	ld	a0,8(a5)
    80001e7c:	6b8c                	ld	a1,16(a5)
    80001e7e:	6f90                	ld	a2,24(a5)
    80001e80:	01073023          	sd	a6,0(a4)
    80001e84:	e708                	sd	a0,8(a4)
    80001e86:	eb0c                	sd	a1,16(a4)
    80001e88:	ef10                	sd	a2,24(a4)
    80001e8a:	02078793          	add	a5,a5,32
    80001e8e:	02070713          	add	a4,a4,32
    80001e92:	fed792e3          	bne	a5,a3,80001e76 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e96:	058a3783          	ld	a5,88(s4)
    80001e9a:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001e9e:	0d0a8493          	add	s1,s5,208
    80001ea2:	0d0a0913          	add	s2,s4,208
    80001ea6:	150a8993          	add	s3,s5,336
    80001eaa:	a00d                	j	80001ecc <fork+0xac>
    freeproc(np);
    80001eac:	8552                	mv	a0,s4
    80001eae:	00000097          	auipc	ra,0x0
    80001eb2:	d46080e7          	jalr	-698(ra) # 80001bf4 <freeproc>
    release(&np->lock);
    80001eb6:	8552                	mv	a0,s4
    80001eb8:	fffff097          	auipc	ra,0xfffff
    80001ebc:	e98080e7          	jalr	-360(ra) # 80000d50 <release>
    return -1;
    80001ec0:	597d                	li	s2,-1
    80001ec2:	a059                	j	80001f48 <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001ec4:	04a1                	add	s1,s1,8
    80001ec6:	0921                	add	s2,s2,8
    80001ec8:	01348b63          	beq	s1,s3,80001ede <fork+0xbe>
    if (p->ofile[i])
    80001ecc:	6088                	ld	a0,0(s1)
    80001ece:	d97d                	beqz	a0,80001ec4 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001ed0:	00003097          	auipc	ra,0x3
    80001ed4:	af2080e7          	jalr	-1294(ra) # 800049c2 <filedup>
    80001ed8:	00a93023          	sd	a0,0(s2)
    80001edc:	b7e5                	j	80001ec4 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001ede:	150ab503          	ld	a0,336(s5)
    80001ee2:	00002097          	auipc	ra,0x2
    80001ee6:	c8a080e7          	jalr	-886(ra) # 80003b6c <idup>
    80001eea:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001eee:	4641                	li	a2,16
    80001ef0:	158a8593          	add	a1,s5,344
    80001ef4:	158a0513          	add	a0,s4,344
    80001ef8:	fffff097          	auipc	ra,0xfffff
    80001efc:	fe8080e7          	jalr	-24(ra) # 80000ee0 <safestrcpy>
  pid = np->pid;
    80001f00:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001f04:	8552                	mv	a0,s4
    80001f06:	fffff097          	auipc	ra,0xfffff
    80001f0a:	e4a080e7          	jalr	-438(ra) # 80000d50 <release>
  acquire(&wait_lock);
    80001f0e:	0022f497          	auipc	s1,0x22f
    80001f12:	c7a48493          	add	s1,s1,-902 # 80230b88 <wait_lock>
    80001f16:	8526                	mv	a0,s1
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	d84080e7          	jalr	-636(ra) # 80000c9c <acquire>
  np->parent = p;
    80001f20:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001f24:	8526                	mv	a0,s1
    80001f26:	fffff097          	auipc	ra,0xfffff
    80001f2a:	e2a080e7          	jalr	-470(ra) # 80000d50 <release>
  acquire(&np->lock);
    80001f2e:	8552                	mv	a0,s4
    80001f30:	fffff097          	auipc	ra,0xfffff
    80001f34:	d6c080e7          	jalr	-660(ra) # 80000c9c <acquire>
  np->state = RUNNABLE;
    80001f38:	478d                	li	a5,3
    80001f3a:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001f3e:	8552                	mv	a0,s4
    80001f40:	fffff097          	auipc	ra,0xfffff
    80001f44:	e10080e7          	jalr	-496(ra) # 80000d50 <release>
}
    80001f48:	854a                	mv	a0,s2
    80001f4a:	70e2                	ld	ra,56(sp)
    80001f4c:	7442                	ld	s0,48(sp)
    80001f4e:	74a2                	ld	s1,40(sp)
    80001f50:	7902                	ld	s2,32(sp)
    80001f52:	69e2                	ld	s3,24(sp)
    80001f54:	6a42                	ld	s4,16(sp)
    80001f56:	6aa2                	ld	s5,8(sp)
    80001f58:	6121                	add	sp,sp,64
    80001f5a:	8082                	ret
    return -1;
    80001f5c:	597d                	li	s2,-1
    80001f5e:	b7ed                	j	80001f48 <fork+0x128>

0000000080001f60 <GetRBI>:
  int GetRBI(uint RTime, uint STime, uint WTime){
    80001f60:	1141                	add	sp,sp,-16
    80001f62:	e422                	sd	s0,8(sp)
    80001f64:	0800                	add	s0,sp,16
    int a = 3*RTime - STime - WTime;
    80001f66:	0015171b          	sllw	a4,a0,0x1
    80001f6a:	9f29                	addw	a4,a4,a0
    80001f6c:	00c587bb          	addw	a5,a1,a2
    80001f70:	9f1d                	subw	a4,a4,a5
    a *= 50;
    80001f72:	03200793          	li	a5,50
    80001f76:	02e787bb          	mulw	a5,a5,a4
    a /= RTime + STime + WTime + 1;
    80001f7a:	2605                	addw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80001f7c:	9db1                	addw	a1,a1,a2
    80001f7e:	9d2d                	addw	a0,a0,a1
    80001f80:	02a7d53b          	divuw	a0,a5,a0
    if (a<0) return 0;
    80001f84:	0005079b          	sext.w	a5,a0
    80001f88:	fff7c793          	not	a5,a5
    80001f8c:	97fd                	sra	a5,a5,0x3f
    80001f8e:	8d7d                	and	a0,a0,a5
  }
    80001f90:	2501                	sext.w	a0,a0
    80001f92:	6422                	ld	s0,8(sp)
    80001f94:	0141                	add	sp,sp,16
    80001f96:	8082                	ret

0000000080001f98 <UpdateTimes>:
  void UpdateTimes(int sel_p_idx){
    80001f98:	715d                	add	sp,sp,-80
    80001f9a:	e486                	sd	ra,72(sp)
    80001f9c:	e0a2                	sd	s0,64(sp)
    80001f9e:	fc26                	sd	s1,56(sp)
    80001fa0:	f84a                	sd	s2,48(sp)
    80001fa2:	f44e                	sd	s3,40(sp)
    80001fa4:	f052                	sd	s4,32(sp)
    80001fa6:	ec56                	sd	s5,24(sp)
    80001fa8:	e85a                	sd	s6,16(sp)
    80001faa:	e45e                	sd	s7,8(sp)
    80001fac:	0880                	add	s0,sp,80
    80001fae:	8a2a                	mv	s4,a0
    for (int p_idx = 0; p_idx < NPROC; p_idx++)
    80001fb0:	0022f497          	auipc	s1,0x22f
    80001fb4:	ff048493          	add	s1,s1,-16 # 80230fa0 <proc>
    80001fb8:	4901                	li	s2,0
        if (proc[p_idx].state == SLEEPING)
    80001fba:	4b09                	li	s6,2
        if (proc[p_idx].state == RUNNABLE)
    80001fbc:	4b8d                	li	s7,3
    for (int p_idx = 0; p_idx < NPROC; p_idx++)
    80001fbe:	04000a93          	li	s5,64
    80001fc2:	a805                	j	80001ff2 <UpdateTimes+0x5a>
        proc[p_idx].RTime ++;
    80001fc4:	1744a783          	lw	a5,372(s1)
    80001fc8:	2785                	addw	a5,a5,1
    80001fca:	16f4aa23          	sw	a5,372(s1)
        proc[p_idx].STime = 0;
    80001fce:	1604ac23          	sw	zero,376(s1)
    80001fd2:	a031                	j	80001fde <UpdateTimes+0x46>
          proc[p_idx].STime ++;
    80001fd4:	1784a783          	lw	a5,376(s1)
    80001fd8:	2785                	addw	a5,a5,1
    80001fda:	16f4ac23          	sw	a5,376(s1)
      release (&proc[p_idx].lock);
    80001fde:	854e                	mv	a0,s3
    80001fe0:	fffff097          	auipc	ra,0xfffff
    80001fe4:	d70080e7          	jalr	-656(ra) # 80000d50 <release>
    for (int p_idx = 0; p_idx < NPROC; p_idx++)
    80001fe8:	2905                	addw	s2,s2,1
    80001fea:	18848493          	add	s1,s1,392
    80001fee:	03590763          	beq	s2,s5,8000201c <UpdateTimes+0x84>
      acquire (&proc[p_idx].lock);
    80001ff2:	89a6                	mv	s3,s1
    80001ff4:	8526                	mv	a0,s1
    80001ff6:	fffff097          	auipc	ra,0xfffff
    80001ffa:	ca6080e7          	jalr	-858(ra) # 80000c9c <acquire>
      if (p_idx == sel_p_idx){
    80001ffe:	fd2a03e3          	beq	s4,s2,80001fc4 <UpdateTimes+0x2c>
        proc[p_idx].RTime = 0;
    80002002:	1604aa23          	sw	zero,372(s1)
        if (proc[p_idx].state == SLEEPING)
    80002006:	4c9c                	lw	a5,24(s1)
    80002008:	fd6786e3          	beq	a5,s6,80001fd4 <UpdateTimes+0x3c>
        if (proc[p_idx].state == RUNNABLE)
    8000200c:	fd7799e3          	bne	a5,s7,80001fde <UpdateTimes+0x46>
          proc[p_idx].WTime ++;
    80002010:	17c4a783          	lw	a5,380(s1)
    80002014:	2785                	addw	a5,a5,1
    80002016:	16f4ae23          	sw	a5,380(s1)
    8000201a:	b7d1                	j	80001fde <UpdateTimes+0x46>
  }
    8000201c:	60a6                	ld	ra,72(sp)
    8000201e:	6406                	ld	s0,64(sp)
    80002020:	74e2                	ld	s1,56(sp)
    80002022:	7942                	ld	s2,48(sp)
    80002024:	79a2                	ld	s3,40(sp)
    80002026:	7a02                	ld	s4,32(sp)
    80002028:	6ae2                	ld	s5,24(sp)
    8000202a:	6b42                	ld	s6,16(sp)
    8000202c:	6ba2                	ld	s7,8(sp)
    8000202e:	6161                	add	sp,sp,80
    80002030:	8082                	ret

0000000080002032 <scheduler>:
{
    80002032:	7175                	add	sp,sp,-144
    80002034:	e506                	sd	ra,136(sp)
    80002036:	e122                	sd	s0,128(sp)
    80002038:	fca6                	sd	s1,120(sp)
    8000203a:	f8ca                	sd	s2,112(sp)
    8000203c:	f4ce                	sd	s3,104(sp)
    8000203e:	f0d2                	sd	s4,96(sp)
    80002040:	ecd6                	sd	s5,88(sp)
    80002042:	e8da                	sd	s6,80(sp)
    80002044:	e4de                	sd	s7,72(sp)
    80002046:	e0e2                	sd	s8,64(sp)
    80002048:	fc66                	sd	s9,56(sp)
    8000204a:	f86a                	sd	s10,48(sp)
    8000204c:	f46e                	sd	s11,40(sp)
    8000204e:	0900                	add	s0,sp,144
    80002050:	8492                	mv	s1,tp
  int id = r_tp();
    80002052:	2481                	sext.w	s1,s1
  c->proc = 0;
    80002054:	00749913          	sll	s2,s1,0x7
    80002058:	0022f797          	auipc	a5,0x22f
    8000205c:	b1878793          	add	a5,a5,-1256 # 80230b70 <pid_lock>
    80002060:	97ca                	add	a5,a5,s2
    80002062:	0207b823          	sd	zero,48(a5)
    printf("Using Scheduler PBS\n");
    80002066:	00006517          	auipc	a0,0x6
    8000206a:	1b250513          	add	a0,a0,434 # 80008218 <digits+0x1d8>
    8000206e:	ffffe097          	auipc	ra,0xffffe
    80002072:	518080e7          	jalr	1304(ra) # 80000586 <printf>
      swtch(&c->context, &p->context);
    80002076:	0022f797          	auipc	a5,0x22f
    8000207a:	b3278793          	add	a5,a5,-1230 # 80230ba8 <cpus+0x8>
    8000207e:	97ca                	add	a5,a5,s2
    80002080:	f8f43023          	sd	a5,-128(s0)
      int min_dp = 100001;
    80002084:	67e1                	lui	a5,0x18
    80002086:	6a178793          	add	a5,a5,1697 # 186a1 <_entry-0x7ffe795f>
    8000208a:	f8f43423          	sd	a5,-120(s0)
      for (int p_idx = 0; p_idx < NPROC; p_idx++)
    8000208e:	04000b13          	li	s6,64
      c->proc = p;
    80002092:	0022f797          	auipc	a5,0x22f
    80002096:	ade78793          	add	a5,a5,-1314 # 80230b70 <pid_lock>
    8000209a:	97ca                	add	a5,a5,s2
    8000209c:	f6f43c23          	sd	a5,-136(s0)
    800020a0:	aa1d                	j	800021d6 <scheduler+0x1a4>
        release(&proc[p_idx].lock);
    800020a2:	8552                	mv	a0,s4
    800020a4:	fffff097          	auipc	ra,0xfffff
    800020a8:	cac080e7          	jalr	-852(ra) # 80000d50 <release>
      for (int p_idx = 0; p_idx < NPROC; p_idx++)
    800020ac:	2905                	addw	s2,s2,1
    800020ae:	18848493          	add	s1,s1,392
    800020b2:	09690263          	beq	s2,s6,80002136 <scheduler+0x104>
        acquire(&proc[p_idx].lock);
    800020b6:	8a26                	mv	s4,s1
    800020b8:	8526                	mv	a0,s1
    800020ba:	fffff097          	auipc	ra,0xfffff
    800020be:	be2080e7          	jalr	-1054(ra) # 80000c9c <acquire>
        if (proc[p_idx].state == RUNNABLE)
    800020c2:	4c9c                	lw	a5,24(s1)
    800020c4:	fd579fe3          	bne	a5,s5,800020a2 <scheduler+0x70>
          int rbi  = GetRBI(p->RTime, p->STime, p->WTime);
    800020c8:	17c4a603          	lw	a2,380(s1)
    800020cc:	1784a583          	lw	a1,376(s1)
    800020d0:	1744a503          	lw	a0,372(s1)
    800020d4:	00000097          	auipc	ra,0x0
    800020d8:	e8c080e7          	jalr	-372(ra) # 80001f60 <GetRBI>
          int dp = p->SP+ rbi;
    800020dc:	1804a983          	lw	s3,384(s1)
    800020e0:	00a989bb          	addw	s3,s3,a0
          if (dp < 0) dp = 0;
    800020e4:	0009879b          	sext.w	a5,s3
    800020e8:	fff7c793          	not	a5,a5
    800020ec:	97fd                	sra	a5,a5,0x3f
    800020ee:	00f9f9b3          	and	s3,s3,a5
    800020f2:	0009879b          	sext.w	a5,s3
    800020f6:	00fcd463          	bge	s9,a5,800020fe <scheduler+0xcc>
    800020fa:	06400993          	li	s3,100
    800020fe:	2981                	sext.w	s3,s3
          printf("> %d %d \n", p->pid, dp);
    80002100:	864e                	mv	a2,s3
    80002102:	030a2583          	lw	a1,48(s4)
    80002106:	8562                	mv	a0,s8
    80002108:	ffffe097          	auipc	ra,0xffffe
    8000210c:	47e080e7          	jalr	1150(ra) # 80000586 <printf>
          if (dp < min_dp || (dp == min_dp && proc[p_idx].ctime <  proc[max_p_idx].ctime) ){
    80002110:	0579c863          	blt	s3,s7,80002160 <scheduler+0x12e>
    80002114:	f93b97e3          	bne	s7,s3,800020a2 <scheduler+0x70>
    80002118:	03bd07b3          	mul	a5,s10,s11
    8000211c:	0022f717          	auipc	a4,0x22f
    80002120:	e8470713          	add	a4,a4,-380 # 80230fa0 <proc>
    80002124:	97ba                	add	a5,a5,a4
    80002126:	16ca2703          	lw	a4,364(s4)
    8000212a:	16c7a783          	lw	a5,364(a5)
    8000212e:	02f76963          	bltu	a4,a5,80002160 <scheduler+0x12e>
    80002132:	8bce                	mv	s7,s3
    80002134:	b7bd                	j	800020a2 <scheduler+0x70>
      if (max_p_idx == -1){
    80002136:	57fd                	li	a5,-1
    80002138:	04fd1463          	bne	s10,a5,80002180 <scheduler+0x14e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000213c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002140:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002144:	10079073          	csrw	sstatus,a5
      for (int p_idx = 0; p_idx < NPROC; p_idx++)
    80002148:	0022f497          	auipc	s1,0x22f
    8000214c:	e5848493          	add	s1,s1,-424 # 80230fa0 <proc>
    80002150:	4901                	li	s2,0
      int min_dp = 100001;
    80002152:	f8843b83          	ld	s7,-120(s0)
      int max_p_idx = -1;
    80002156:	5d7d                	li	s10,-1
        if (proc[p_idx].state == RUNNABLE)
    80002158:	4a8d                	li	s5,3
          if (dp < min_dp || (dp == min_dp && proc[p_idx].ctime <  proc[max_p_idx].ctime) ){
    8000215a:	18800d93          	li	s11,392
    8000215e:	bfa1                	j	800020b6 <scheduler+0x84>
        release(&proc[p_idx].lock);
    80002160:	8552                	mv	a0,s4
    80002162:	fffff097          	auipc	ra,0xfffff
    80002166:	bee080e7          	jalr	-1042(ra) # 80000d50 <release>
      for (int p_idx = 0; p_idx < NPROC; p_idx++)
    8000216a:	0019079b          	addw	a5,s2,1
    8000216e:	18848493          	add	s1,s1,392
    80002172:	01678663          	beq	a5,s6,8000217e <scheduler+0x14c>
    80002176:	8bce                	mv	s7,s3
    80002178:	8d4a                	mv	s10,s2
    8000217a:	893e                	mv	s2,a5
    8000217c:	bf2d                	j	800020b6 <scheduler+0x84>
    8000217e:	8d4a                	mv	s10,s2
      UpdateTimes(max_p_idx);
    80002180:	856a                	mv	a0,s10
    80002182:	00000097          	auipc	ra,0x0
    80002186:	e16080e7          	jalr	-490(ra) # 80001f98 <UpdateTimes>
      p = &proc[max_p_idx];
    8000218a:	18800493          	li	s1,392
    8000218e:	029d04b3          	mul	s1,s10,s1
    80002192:	0022f997          	auipc	s3,0x22f
    80002196:	e0e98993          	add	s3,s3,-498 # 80230fa0 <proc>
    8000219a:	01348933          	add	s2,s1,s3
      acquire(&p->lock);
    8000219e:	854a                	mv	a0,s2
    800021a0:	fffff097          	auipc	ra,0xfffff
    800021a4:	afc080e7          	jalr	-1284(ra) # 80000c9c <acquire>
      p->state = RUNNING;
    800021a8:	4791                	li	a5,4
    800021aa:	00f92c23          	sw	a5,24(s2)
      c->proc = p;
    800021ae:	f7843a03          	ld	s4,-136(s0)
    800021b2:	032a3823          	sd	s2,48(s4)
      swtch(&c->context, &p->context);
    800021b6:	06048593          	add	a1,s1,96
    800021ba:	95ce                	add	a1,a1,s3
    800021bc:	f8043503          	ld	a0,-128(s0)
    800021c0:	00001097          	auipc	ra,0x1
    800021c4:	850080e7          	jalr	-1968(ra) # 80002a10 <swtch>
      c->proc = 0;
    800021c8:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    800021cc:	854a                	mv	a0,s2
    800021ce:	fffff097          	auipc	ra,0xfffff
    800021d2:	b82080e7          	jalr	-1150(ra) # 80000d50 <release>
    800021d6:	06400c93          	li	s9,100
          printf("> %d %d \n", p->pid, dp);
    800021da:	00006c17          	auipc	s8,0x6
    800021de:	056c0c13          	add	s8,s8,86 # 80008230 <digits+0x1f0>
    800021e2:	bfa9                	j	8000213c <scheduler+0x10a>

00000000800021e4 <sched>:
{
    800021e4:	7179                	add	sp,sp,-48
    800021e6:	f406                	sd	ra,40(sp)
    800021e8:	f022                	sd	s0,32(sp)
    800021ea:	ec26                	sd	s1,24(sp)
    800021ec:	e84a                	sd	s2,16(sp)
    800021ee:	e44e                	sd	s3,8(sp)
    800021f0:	1800                	add	s0,sp,48
  struct proc *p = myproc();
    800021f2:	00000097          	auipc	ra,0x0
    800021f6:	850080e7          	jalr	-1968(ra) # 80001a42 <myproc>
    800021fa:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800021fc:	fffff097          	auipc	ra,0xfffff
    80002200:	a26080e7          	jalr	-1498(ra) # 80000c22 <holding>
    80002204:	c93d                	beqz	a0,8000227a <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002206:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002208:	2781                	sext.w	a5,a5
    8000220a:	079e                	sll	a5,a5,0x7
    8000220c:	0022f717          	auipc	a4,0x22f
    80002210:	96470713          	add	a4,a4,-1692 # 80230b70 <pid_lock>
    80002214:	97ba                	add	a5,a5,a4
    80002216:	0a87a703          	lw	a4,168(a5)
    8000221a:	4785                	li	a5,1
    8000221c:	06f71763          	bne	a4,a5,8000228a <sched+0xa6>
  if (p->state == RUNNING)
    80002220:	4c98                	lw	a4,24(s1)
    80002222:	4791                	li	a5,4
    80002224:	06f70b63          	beq	a4,a5,8000229a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002228:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000222c:	8b89                	and	a5,a5,2
  if (intr_get())
    8000222e:	efb5                	bnez	a5,800022aa <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002230:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002232:	0022f917          	auipc	s2,0x22f
    80002236:	93e90913          	add	s2,s2,-1730 # 80230b70 <pid_lock>
    8000223a:	2781                	sext.w	a5,a5
    8000223c:	079e                	sll	a5,a5,0x7
    8000223e:	97ca                	add	a5,a5,s2
    80002240:	0ac7a983          	lw	s3,172(a5)
    80002244:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002246:	2781                	sext.w	a5,a5
    80002248:	079e                	sll	a5,a5,0x7
    8000224a:	0022f597          	auipc	a1,0x22f
    8000224e:	95e58593          	add	a1,a1,-1698 # 80230ba8 <cpus+0x8>
    80002252:	95be                	add	a1,a1,a5
    80002254:	06048513          	add	a0,s1,96
    80002258:	00000097          	auipc	ra,0x0
    8000225c:	7b8080e7          	jalr	1976(ra) # 80002a10 <swtch>
    80002260:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002262:	2781                	sext.w	a5,a5
    80002264:	079e                	sll	a5,a5,0x7
    80002266:	993e                	add	s2,s2,a5
    80002268:	0b392623          	sw	s3,172(s2)
}
    8000226c:	70a2                	ld	ra,40(sp)
    8000226e:	7402                	ld	s0,32(sp)
    80002270:	64e2                	ld	s1,24(sp)
    80002272:	6942                	ld	s2,16(sp)
    80002274:	69a2                	ld	s3,8(sp)
    80002276:	6145                	add	sp,sp,48
    80002278:	8082                	ret
    panic("sched p->lock");
    8000227a:	00006517          	auipc	a0,0x6
    8000227e:	fc650513          	add	a0,a0,-58 # 80008240 <digits+0x200>
    80002282:	ffffe097          	auipc	ra,0xffffe
    80002286:	2ba080e7          	jalr	698(ra) # 8000053c <panic>
    panic("sched locks");
    8000228a:	00006517          	auipc	a0,0x6
    8000228e:	fc650513          	add	a0,a0,-58 # 80008250 <digits+0x210>
    80002292:	ffffe097          	auipc	ra,0xffffe
    80002296:	2aa080e7          	jalr	682(ra) # 8000053c <panic>
    panic("sched running");
    8000229a:	00006517          	auipc	a0,0x6
    8000229e:	fc650513          	add	a0,a0,-58 # 80008260 <digits+0x220>
    800022a2:	ffffe097          	auipc	ra,0xffffe
    800022a6:	29a080e7          	jalr	666(ra) # 8000053c <panic>
    panic("sched interruptible");
    800022aa:	00006517          	auipc	a0,0x6
    800022ae:	fc650513          	add	a0,a0,-58 # 80008270 <digits+0x230>
    800022b2:	ffffe097          	auipc	ra,0xffffe
    800022b6:	28a080e7          	jalr	650(ra) # 8000053c <panic>

00000000800022ba <yield>:
{
    800022ba:	1101                	add	sp,sp,-32
    800022bc:	ec06                	sd	ra,24(sp)
    800022be:	e822                	sd	s0,16(sp)
    800022c0:	e426                	sd	s1,8(sp)
    800022c2:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    800022c4:	fffff097          	auipc	ra,0xfffff
    800022c8:	77e080e7          	jalr	1918(ra) # 80001a42 <myproc>
    800022cc:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022ce:	fffff097          	auipc	ra,0xfffff
    800022d2:	9ce080e7          	jalr	-1586(ra) # 80000c9c <acquire>
  p->state = RUNNABLE;
    800022d6:	478d                	li	a5,3
    800022d8:	cc9c                	sw	a5,24(s1)
  sched();
    800022da:	00000097          	auipc	ra,0x0
    800022de:	f0a080e7          	jalr	-246(ra) # 800021e4 <sched>
  release(&p->lock);
    800022e2:	8526                	mv	a0,s1
    800022e4:	fffff097          	auipc	ra,0xfffff
    800022e8:	a6c080e7          	jalr	-1428(ra) # 80000d50 <release>
}
    800022ec:	60e2                	ld	ra,24(sp)
    800022ee:	6442                	ld	s0,16(sp)
    800022f0:	64a2                	ld	s1,8(sp)
    800022f2:	6105                	add	sp,sp,32
    800022f4:	8082                	ret

00000000800022f6 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800022f6:	7179                	add	sp,sp,-48
    800022f8:	f406                	sd	ra,40(sp)
    800022fa:	f022                	sd	s0,32(sp)
    800022fc:	ec26                	sd	s1,24(sp)
    800022fe:	e84a                	sd	s2,16(sp)
    80002300:	e44e                	sd	s3,8(sp)
    80002302:	1800                	add	s0,sp,48
    80002304:	89aa                	mv	s3,a0
    80002306:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002308:	fffff097          	auipc	ra,0xfffff
    8000230c:	73a080e7          	jalr	1850(ra) # 80001a42 <myproc>
    80002310:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80002312:	fffff097          	auipc	ra,0xfffff
    80002316:	98a080e7          	jalr	-1654(ra) # 80000c9c <acquire>
  release(lk);
    8000231a:	854a                	mv	a0,s2
    8000231c:	fffff097          	auipc	ra,0xfffff
    80002320:	a34080e7          	jalr	-1484(ra) # 80000d50 <release>

  // Go to sleep.
  p->chan = chan;
    80002324:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002328:	4789                	li	a5,2
    8000232a:	cc9c                	sw	a5,24(s1)

  sched();
    8000232c:	00000097          	auipc	ra,0x0
    80002330:	eb8080e7          	jalr	-328(ra) # 800021e4 <sched>

  // Tidy up.
  p->chan = 0;
    80002334:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002338:	8526                	mv	a0,s1
    8000233a:	fffff097          	auipc	ra,0xfffff
    8000233e:	a16080e7          	jalr	-1514(ra) # 80000d50 <release>
  acquire(lk);
    80002342:	854a                	mv	a0,s2
    80002344:	fffff097          	auipc	ra,0xfffff
    80002348:	958080e7          	jalr	-1704(ra) # 80000c9c <acquire>
}
    8000234c:	70a2                	ld	ra,40(sp)
    8000234e:	7402                	ld	s0,32(sp)
    80002350:	64e2                	ld	s1,24(sp)
    80002352:	6942                	ld	s2,16(sp)
    80002354:	69a2                	ld	s3,8(sp)
    80002356:	6145                	add	sp,sp,48
    80002358:	8082                	ret

000000008000235a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    8000235a:	7139                	add	sp,sp,-64
    8000235c:	fc06                	sd	ra,56(sp)
    8000235e:	f822                	sd	s0,48(sp)
    80002360:	f426                	sd	s1,40(sp)
    80002362:	f04a                	sd	s2,32(sp)
    80002364:	ec4e                	sd	s3,24(sp)
    80002366:	e852                	sd	s4,16(sp)
    80002368:	e456                	sd	s5,8(sp)
    8000236a:	0080                	add	s0,sp,64
    8000236c:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000236e:	0022f497          	auipc	s1,0x22f
    80002372:	c3248493          	add	s1,s1,-974 # 80230fa0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002376:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002378:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    8000237a:	00235917          	auipc	s2,0x235
    8000237e:	e2690913          	add	s2,s2,-474 # 802371a0 <tickslock>
    80002382:	a811                	j	80002396 <wakeup+0x3c>
      }
      release(&p->lock);
    80002384:	8526                	mv	a0,s1
    80002386:	fffff097          	auipc	ra,0xfffff
    8000238a:	9ca080e7          	jalr	-1590(ra) # 80000d50 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000238e:	18848493          	add	s1,s1,392
    80002392:	03248663          	beq	s1,s2,800023be <wakeup+0x64>
    if (p != myproc())
    80002396:	fffff097          	auipc	ra,0xfffff
    8000239a:	6ac080e7          	jalr	1708(ra) # 80001a42 <myproc>
    8000239e:	fea488e3          	beq	s1,a0,8000238e <wakeup+0x34>
      acquire(&p->lock);
    800023a2:	8526                	mv	a0,s1
    800023a4:	fffff097          	auipc	ra,0xfffff
    800023a8:	8f8080e7          	jalr	-1800(ra) # 80000c9c <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    800023ac:	4c9c                	lw	a5,24(s1)
    800023ae:	fd379be3          	bne	a5,s3,80002384 <wakeup+0x2a>
    800023b2:	709c                	ld	a5,32(s1)
    800023b4:	fd4798e3          	bne	a5,s4,80002384 <wakeup+0x2a>
        p->state = RUNNABLE;
    800023b8:	0154ac23          	sw	s5,24(s1)
    800023bc:	b7e1                	j	80002384 <wakeup+0x2a>
    }
  }
}
    800023be:	70e2                	ld	ra,56(sp)
    800023c0:	7442                	ld	s0,48(sp)
    800023c2:	74a2                	ld	s1,40(sp)
    800023c4:	7902                	ld	s2,32(sp)
    800023c6:	69e2                	ld	s3,24(sp)
    800023c8:	6a42                	ld	s4,16(sp)
    800023ca:	6aa2                	ld	s5,8(sp)
    800023cc:	6121                	add	sp,sp,64
    800023ce:	8082                	ret

00000000800023d0 <reparent>:
{
    800023d0:	7179                	add	sp,sp,-48
    800023d2:	f406                	sd	ra,40(sp)
    800023d4:	f022                	sd	s0,32(sp)
    800023d6:	ec26                	sd	s1,24(sp)
    800023d8:	e84a                	sd	s2,16(sp)
    800023da:	e44e                	sd	s3,8(sp)
    800023dc:	e052                	sd	s4,0(sp)
    800023de:	1800                	add	s0,sp,48
    800023e0:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800023e2:	0022f497          	auipc	s1,0x22f
    800023e6:	bbe48493          	add	s1,s1,-1090 # 80230fa0 <proc>
      pp->parent = initproc;
    800023ea:	00006a17          	auipc	s4,0x6
    800023ee:	50ea0a13          	add	s4,s4,1294 # 800088f8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800023f2:	00235997          	auipc	s3,0x235
    800023f6:	dae98993          	add	s3,s3,-594 # 802371a0 <tickslock>
    800023fa:	a029                	j	80002404 <reparent+0x34>
    800023fc:	18848493          	add	s1,s1,392
    80002400:	01348d63          	beq	s1,s3,8000241a <reparent+0x4a>
    if (pp->parent == p)
    80002404:	7c9c                	ld	a5,56(s1)
    80002406:	ff279be3          	bne	a5,s2,800023fc <reparent+0x2c>
      pp->parent = initproc;
    8000240a:	000a3503          	ld	a0,0(s4)
    8000240e:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002410:	00000097          	auipc	ra,0x0
    80002414:	f4a080e7          	jalr	-182(ra) # 8000235a <wakeup>
    80002418:	b7d5                	j	800023fc <reparent+0x2c>
}
    8000241a:	70a2                	ld	ra,40(sp)
    8000241c:	7402                	ld	s0,32(sp)
    8000241e:	64e2                	ld	s1,24(sp)
    80002420:	6942                	ld	s2,16(sp)
    80002422:	69a2                	ld	s3,8(sp)
    80002424:	6a02                	ld	s4,0(sp)
    80002426:	6145                	add	sp,sp,48
    80002428:	8082                	ret

000000008000242a <exit>:
{
    8000242a:	7179                	add	sp,sp,-48
    8000242c:	f406                	sd	ra,40(sp)
    8000242e:	f022                	sd	s0,32(sp)
    80002430:	ec26                	sd	s1,24(sp)
    80002432:	e84a                	sd	s2,16(sp)
    80002434:	e44e                	sd	s3,8(sp)
    80002436:	e052                	sd	s4,0(sp)
    80002438:	1800                	add	s0,sp,48
    8000243a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000243c:	fffff097          	auipc	ra,0xfffff
    80002440:	606080e7          	jalr	1542(ra) # 80001a42 <myproc>
    80002444:	89aa                	mv	s3,a0
  if (p == initproc)
    80002446:	00006797          	auipc	a5,0x6
    8000244a:	4b27b783          	ld	a5,1202(a5) # 800088f8 <initproc>
    8000244e:	0d050493          	add	s1,a0,208
    80002452:	15050913          	add	s2,a0,336
    80002456:	02a79363          	bne	a5,a0,8000247c <exit+0x52>
    panic("init exiting");
    8000245a:	00006517          	auipc	a0,0x6
    8000245e:	e2e50513          	add	a0,a0,-466 # 80008288 <digits+0x248>
    80002462:	ffffe097          	auipc	ra,0xffffe
    80002466:	0da080e7          	jalr	218(ra) # 8000053c <panic>
      fileclose(f);
    8000246a:	00002097          	auipc	ra,0x2
    8000246e:	5aa080e7          	jalr	1450(ra) # 80004a14 <fileclose>
      p->ofile[fd] = 0;
    80002472:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002476:	04a1                	add	s1,s1,8
    80002478:	01248563          	beq	s1,s2,80002482 <exit+0x58>
    if (p->ofile[fd])
    8000247c:	6088                	ld	a0,0(s1)
    8000247e:	f575                	bnez	a0,8000246a <exit+0x40>
    80002480:	bfdd                	j	80002476 <exit+0x4c>
  begin_op();
    80002482:	00002097          	auipc	ra,0x2
    80002486:	0ce080e7          	jalr	206(ra) # 80004550 <begin_op>
  iput(p->cwd);
    8000248a:	1509b503          	ld	a0,336(s3)
    8000248e:	00002097          	auipc	ra,0x2
    80002492:	8d6080e7          	jalr	-1834(ra) # 80003d64 <iput>
  end_op();
    80002496:	00002097          	auipc	ra,0x2
    8000249a:	134080e7          	jalr	308(ra) # 800045ca <end_op>
  p->cwd = 0;
    8000249e:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800024a2:	0022e497          	auipc	s1,0x22e
    800024a6:	6e648493          	add	s1,s1,1766 # 80230b88 <wait_lock>
    800024aa:	8526                	mv	a0,s1
    800024ac:	ffffe097          	auipc	ra,0xffffe
    800024b0:	7f0080e7          	jalr	2032(ra) # 80000c9c <acquire>
  reparent(p);
    800024b4:	854e                	mv	a0,s3
    800024b6:	00000097          	auipc	ra,0x0
    800024ba:	f1a080e7          	jalr	-230(ra) # 800023d0 <reparent>
  wakeup(p->parent);
    800024be:	0389b503          	ld	a0,56(s3)
    800024c2:	00000097          	auipc	ra,0x0
    800024c6:	e98080e7          	jalr	-360(ra) # 8000235a <wakeup>
  acquire(&p->lock);
    800024ca:	854e                	mv	a0,s3
    800024cc:	ffffe097          	auipc	ra,0xffffe
    800024d0:	7d0080e7          	jalr	2000(ra) # 80000c9c <acquire>
  p->xstate = status;
    800024d4:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800024d8:	4795                	li	a5,5
    800024da:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800024de:	00006797          	auipc	a5,0x6
    800024e2:	4227a783          	lw	a5,1058(a5) # 80008900 <ticks>
    800024e6:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    800024ea:	8526                	mv	a0,s1
    800024ec:	fffff097          	auipc	ra,0xfffff
    800024f0:	864080e7          	jalr	-1948(ra) # 80000d50 <release>
  sched();
    800024f4:	00000097          	auipc	ra,0x0
    800024f8:	cf0080e7          	jalr	-784(ra) # 800021e4 <sched>
  panic("zombie exit");
    800024fc:	00006517          	auipc	a0,0x6
    80002500:	d9c50513          	add	a0,a0,-612 # 80008298 <digits+0x258>
    80002504:	ffffe097          	auipc	ra,0xffffe
    80002508:	038080e7          	jalr	56(ra) # 8000053c <panic>

000000008000250c <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000250c:	7179                	add	sp,sp,-48
    8000250e:	f406                	sd	ra,40(sp)
    80002510:	f022                	sd	s0,32(sp)
    80002512:	ec26                	sd	s1,24(sp)
    80002514:	e84a                	sd	s2,16(sp)
    80002516:	e44e                	sd	s3,8(sp)
    80002518:	1800                	add	s0,sp,48
    8000251a:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000251c:	0022f497          	auipc	s1,0x22f
    80002520:	a8448493          	add	s1,s1,-1404 # 80230fa0 <proc>
    80002524:	00235997          	auipc	s3,0x235
    80002528:	c7c98993          	add	s3,s3,-900 # 802371a0 <tickslock>
  {
    acquire(&p->lock);
    8000252c:	8526                	mv	a0,s1
    8000252e:	ffffe097          	auipc	ra,0xffffe
    80002532:	76e080e7          	jalr	1902(ra) # 80000c9c <acquire>
    if (p->pid == pid)
    80002536:	589c                	lw	a5,48(s1)
    80002538:	01278d63          	beq	a5,s2,80002552 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000253c:	8526                	mv	a0,s1
    8000253e:	fffff097          	auipc	ra,0xfffff
    80002542:	812080e7          	jalr	-2030(ra) # 80000d50 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002546:	18848493          	add	s1,s1,392
    8000254a:	ff3491e3          	bne	s1,s3,8000252c <kill+0x20>
  }
  return -1;
    8000254e:	557d                	li	a0,-1
    80002550:	a829                	j	8000256a <kill+0x5e>
      p->killed = 1;
    80002552:	4785                	li	a5,1
    80002554:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002556:	4c98                	lw	a4,24(s1)
    80002558:	4789                	li	a5,2
    8000255a:	00f70f63          	beq	a4,a5,80002578 <kill+0x6c>
      release(&p->lock);
    8000255e:	8526                	mv	a0,s1
    80002560:	ffffe097          	auipc	ra,0xffffe
    80002564:	7f0080e7          	jalr	2032(ra) # 80000d50 <release>
      return 0;
    80002568:	4501                	li	a0,0
}
    8000256a:	70a2                	ld	ra,40(sp)
    8000256c:	7402                	ld	s0,32(sp)
    8000256e:	64e2                	ld	s1,24(sp)
    80002570:	6942                	ld	s2,16(sp)
    80002572:	69a2                	ld	s3,8(sp)
    80002574:	6145                	add	sp,sp,48
    80002576:	8082                	ret
        p->state = RUNNABLE;
    80002578:	478d                	li	a5,3
    8000257a:	cc9c                	sw	a5,24(s1)
    8000257c:	b7cd                	j	8000255e <kill+0x52>

000000008000257e <setkilled>:

void setkilled(struct proc *p)
{
    8000257e:	1101                	add	sp,sp,-32
    80002580:	ec06                	sd	ra,24(sp)
    80002582:	e822                	sd	s0,16(sp)
    80002584:	e426                	sd	s1,8(sp)
    80002586:	1000                	add	s0,sp,32
    80002588:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000258a:	ffffe097          	auipc	ra,0xffffe
    8000258e:	712080e7          	jalr	1810(ra) # 80000c9c <acquire>
  p->killed = 1;
    80002592:	4785                	li	a5,1
    80002594:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002596:	8526                	mv	a0,s1
    80002598:	ffffe097          	auipc	ra,0xffffe
    8000259c:	7b8080e7          	jalr	1976(ra) # 80000d50 <release>
}
    800025a0:	60e2                	ld	ra,24(sp)
    800025a2:	6442                	ld	s0,16(sp)
    800025a4:	64a2                	ld	s1,8(sp)
    800025a6:	6105                	add	sp,sp,32
    800025a8:	8082                	ret

00000000800025aa <killed>:

int killed(struct proc *p)
{
    800025aa:	1101                	add	sp,sp,-32
    800025ac:	ec06                	sd	ra,24(sp)
    800025ae:	e822                	sd	s0,16(sp)
    800025b0:	e426                	sd	s1,8(sp)
    800025b2:	e04a                	sd	s2,0(sp)
    800025b4:	1000                	add	s0,sp,32
    800025b6:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    800025b8:	ffffe097          	auipc	ra,0xffffe
    800025bc:	6e4080e7          	jalr	1764(ra) # 80000c9c <acquire>
  k = p->killed;
    800025c0:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800025c4:	8526                	mv	a0,s1
    800025c6:	ffffe097          	auipc	ra,0xffffe
    800025ca:	78a080e7          	jalr	1930(ra) # 80000d50 <release>
  return k;
}
    800025ce:	854a                	mv	a0,s2
    800025d0:	60e2                	ld	ra,24(sp)
    800025d2:	6442                	ld	s0,16(sp)
    800025d4:	64a2                	ld	s1,8(sp)
    800025d6:	6902                	ld	s2,0(sp)
    800025d8:	6105                	add	sp,sp,32
    800025da:	8082                	ret

00000000800025dc <wait>:
{
    800025dc:	715d                	add	sp,sp,-80
    800025de:	e486                	sd	ra,72(sp)
    800025e0:	e0a2                	sd	s0,64(sp)
    800025e2:	fc26                	sd	s1,56(sp)
    800025e4:	f84a                	sd	s2,48(sp)
    800025e6:	f44e                	sd	s3,40(sp)
    800025e8:	f052                	sd	s4,32(sp)
    800025ea:	ec56                	sd	s5,24(sp)
    800025ec:	e85a                	sd	s6,16(sp)
    800025ee:	e45e                	sd	s7,8(sp)
    800025f0:	e062                	sd	s8,0(sp)
    800025f2:	0880                	add	s0,sp,80
    800025f4:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800025f6:	fffff097          	auipc	ra,0xfffff
    800025fa:	44c080e7          	jalr	1100(ra) # 80001a42 <myproc>
    800025fe:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002600:	0022e517          	auipc	a0,0x22e
    80002604:	58850513          	add	a0,a0,1416 # 80230b88 <wait_lock>
    80002608:	ffffe097          	auipc	ra,0xffffe
    8000260c:	694080e7          	jalr	1684(ra) # 80000c9c <acquire>
    havekids = 0;
    80002610:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    80002612:	4a15                	li	s4,5
        havekids = 1;
    80002614:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002616:	00235997          	auipc	s3,0x235
    8000261a:	b8a98993          	add	s3,s3,-1142 # 802371a0 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000261e:	0022ec17          	auipc	s8,0x22e
    80002622:	56ac0c13          	add	s8,s8,1386 # 80230b88 <wait_lock>
    80002626:	a0d1                	j	800026ea <wait+0x10e>
          pid = pp->pid;
    80002628:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000262c:	000b0e63          	beqz	s6,80002648 <wait+0x6c>
    80002630:	4691                	li	a3,4
    80002632:	02c48613          	add	a2,s1,44
    80002636:	85da                	mv	a1,s6
    80002638:	05093503          	ld	a0,80(s2)
    8000263c:	fffff097          	auipc	ra,0xfffff
    80002640:	0c6080e7          	jalr	198(ra) # 80001702 <copyout>
    80002644:	04054163          	bltz	a0,80002686 <wait+0xaa>
          freeproc(pp);
    80002648:	8526                	mv	a0,s1
    8000264a:	fffff097          	auipc	ra,0xfffff
    8000264e:	5aa080e7          	jalr	1450(ra) # 80001bf4 <freeproc>
          release(&pp->lock);
    80002652:	8526                	mv	a0,s1
    80002654:	ffffe097          	auipc	ra,0xffffe
    80002658:	6fc080e7          	jalr	1788(ra) # 80000d50 <release>
          release(&wait_lock);
    8000265c:	0022e517          	auipc	a0,0x22e
    80002660:	52c50513          	add	a0,a0,1324 # 80230b88 <wait_lock>
    80002664:	ffffe097          	auipc	ra,0xffffe
    80002668:	6ec080e7          	jalr	1772(ra) # 80000d50 <release>
}
    8000266c:	854e                	mv	a0,s3
    8000266e:	60a6                	ld	ra,72(sp)
    80002670:	6406                	ld	s0,64(sp)
    80002672:	74e2                	ld	s1,56(sp)
    80002674:	7942                	ld	s2,48(sp)
    80002676:	79a2                	ld	s3,40(sp)
    80002678:	7a02                	ld	s4,32(sp)
    8000267a:	6ae2                	ld	s5,24(sp)
    8000267c:	6b42                	ld	s6,16(sp)
    8000267e:	6ba2                	ld	s7,8(sp)
    80002680:	6c02                	ld	s8,0(sp)
    80002682:	6161                	add	sp,sp,80
    80002684:	8082                	ret
            release(&pp->lock);
    80002686:	8526                	mv	a0,s1
    80002688:	ffffe097          	auipc	ra,0xffffe
    8000268c:	6c8080e7          	jalr	1736(ra) # 80000d50 <release>
            release(&wait_lock);
    80002690:	0022e517          	auipc	a0,0x22e
    80002694:	4f850513          	add	a0,a0,1272 # 80230b88 <wait_lock>
    80002698:	ffffe097          	auipc	ra,0xffffe
    8000269c:	6b8080e7          	jalr	1720(ra) # 80000d50 <release>
            return -1;
    800026a0:	59fd                	li	s3,-1
    800026a2:	b7e9                	j	8000266c <wait+0x90>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800026a4:	18848493          	add	s1,s1,392
    800026a8:	03348463          	beq	s1,s3,800026d0 <wait+0xf4>
      if (pp->parent == p)
    800026ac:	7c9c                	ld	a5,56(s1)
    800026ae:	ff279be3          	bne	a5,s2,800026a4 <wait+0xc8>
        acquire(&pp->lock);
    800026b2:	8526                	mv	a0,s1
    800026b4:	ffffe097          	auipc	ra,0xffffe
    800026b8:	5e8080e7          	jalr	1512(ra) # 80000c9c <acquire>
        if (pp->state == ZOMBIE)
    800026bc:	4c9c                	lw	a5,24(s1)
    800026be:	f74785e3          	beq	a5,s4,80002628 <wait+0x4c>
        release(&pp->lock);
    800026c2:	8526                	mv	a0,s1
    800026c4:	ffffe097          	auipc	ra,0xffffe
    800026c8:	68c080e7          	jalr	1676(ra) # 80000d50 <release>
        havekids = 1;
    800026cc:	8756                	mv	a4,s5
    800026ce:	bfd9                	j	800026a4 <wait+0xc8>
    if (!havekids || killed(p))
    800026d0:	c31d                	beqz	a4,800026f6 <wait+0x11a>
    800026d2:	854a                	mv	a0,s2
    800026d4:	00000097          	auipc	ra,0x0
    800026d8:	ed6080e7          	jalr	-298(ra) # 800025aa <killed>
    800026dc:	ed09                	bnez	a0,800026f6 <wait+0x11a>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800026de:	85e2                	mv	a1,s8
    800026e0:	854a                	mv	a0,s2
    800026e2:	00000097          	auipc	ra,0x0
    800026e6:	c14080e7          	jalr	-1004(ra) # 800022f6 <sleep>
    havekids = 0;
    800026ea:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800026ec:	0022f497          	auipc	s1,0x22f
    800026f0:	8b448493          	add	s1,s1,-1868 # 80230fa0 <proc>
    800026f4:	bf65                	j	800026ac <wait+0xd0>
      release(&wait_lock);
    800026f6:	0022e517          	auipc	a0,0x22e
    800026fa:	49250513          	add	a0,a0,1170 # 80230b88 <wait_lock>
    800026fe:	ffffe097          	auipc	ra,0xffffe
    80002702:	652080e7          	jalr	1618(ra) # 80000d50 <release>
      return -1;
    80002706:	59fd                	li	s3,-1
    80002708:	b795                	j	8000266c <wait+0x90>

000000008000270a <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000270a:	7179                	add	sp,sp,-48
    8000270c:	f406                	sd	ra,40(sp)
    8000270e:	f022                	sd	s0,32(sp)
    80002710:	ec26                	sd	s1,24(sp)
    80002712:	e84a                	sd	s2,16(sp)
    80002714:	e44e                	sd	s3,8(sp)
    80002716:	e052                	sd	s4,0(sp)
    80002718:	1800                	add	s0,sp,48
    8000271a:	84aa                	mv	s1,a0
    8000271c:	892e                	mv	s2,a1
    8000271e:	89b2                	mv	s3,a2
    80002720:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002722:	fffff097          	auipc	ra,0xfffff
    80002726:	320080e7          	jalr	800(ra) # 80001a42 <myproc>
  if (user_dst)
    8000272a:	c08d                	beqz	s1,8000274c <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    8000272c:	86d2                	mv	a3,s4
    8000272e:	864e                	mv	a2,s3
    80002730:	85ca                	mv	a1,s2
    80002732:	6928                	ld	a0,80(a0)
    80002734:	fffff097          	auipc	ra,0xfffff
    80002738:	fce080e7          	jalr	-50(ra) # 80001702 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000273c:	70a2                	ld	ra,40(sp)
    8000273e:	7402                	ld	s0,32(sp)
    80002740:	64e2                	ld	s1,24(sp)
    80002742:	6942                	ld	s2,16(sp)
    80002744:	69a2                	ld	s3,8(sp)
    80002746:	6a02                	ld	s4,0(sp)
    80002748:	6145                	add	sp,sp,48
    8000274a:	8082                	ret
    memmove((char *)dst, src, len);
    8000274c:	000a061b          	sext.w	a2,s4
    80002750:	85ce                	mv	a1,s3
    80002752:	854a                	mv	a0,s2
    80002754:	ffffe097          	auipc	ra,0xffffe
    80002758:	6a0080e7          	jalr	1696(ra) # 80000df4 <memmove>
    return 0;
    8000275c:	8526                	mv	a0,s1
    8000275e:	bff9                	j	8000273c <either_copyout+0x32>

0000000080002760 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002760:	7179                	add	sp,sp,-48
    80002762:	f406                	sd	ra,40(sp)
    80002764:	f022                	sd	s0,32(sp)
    80002766:	ec26                	sd	s1,24(sp)
    80002768:	e84a                	sd	s2,16(sp)
    8000276a:	e44e                	sd	s3,8(sp)
    8000276c:	e052                	sd	s4,0(sp)
    8000276e:	1800                	add	s0,sp,48
    80002770:	892a                	mv	s2,a0
    80002772:	84ae                	mv	s1,a1
    80002774:	89b2                	mv	s3,a2
    80002776:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002778:	fffff097          	auipc	ra,0xfffff
    8000277c:	2ca080e7          	jalr	714(ra) # 80001a42 <myproc>
  if (user_src)
    80002780:	c08d                	beqz	s1,800027a2 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002782:	86d2                	mv	a3,s4
    80002784:	864e                	mv	a2,s3
    80002786:	85ca                	mv	a1,s2
    80002788:	6928                	ld	a0,80(a0)
    8000278a:	fffff097          	auipc	ra,0xfffff
    8000278e:	004080e7          	jalr	4(ra) # 8000178e <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002792:	70a2                	ld	ra,40(sp)
    80002794:	7402                	ld	s0,32(sp)
    80002796:	64e2                	ld	s1,24(sp)
    80002798:	6942                	ld	s2,16(sp)
    8000279a:	69a2                	ld	s3,8(sp)
    8000279c:	6a02                	ld	s4,0(sp)
    8000279e:	6145                	add	sp,sp,48
    800027a0:	8082                	ret
    memmove(dst, (char *)src, len);
    800027a2:	000a061b          	sext.w	a2,s4
    800027a6:	85ce                	mv	a1,s3
    800027a8:	854a                	mv	a0,s2
    800027aa:	ffffe097          	auipc	ra,0xffffe
    800027ae:	64a080e7          	jalr	1610(ra) # 80000df4 <memmove>
    return 0;
    800027b2:	8526                	mv	a0,s1
    800027b4:	bff9                	j	80002792 <either_copyin+0x32>

00000000800027b6 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800027b6:	715d                	add	sp,sp,-80
    800027b8:	e486                	sd	ra,72(sp)
    800027ba:	e0a2                	sd	s0,64(sp)
    800027bc:	fc26                	sd	s1,56(sp)
    800027be:	f84a                	sd	s2,48(sp)
    800027c0:	f44e                	sd	s3,40(sp)
    800027c2:	f052                	sd	s4,32(sp)
    800027c4:	ec56                	sd	s5,24(sp)
    800027c6:	e85a                	sd	s6,16(sp)
    800027c8:	e45e                	sd	s7,8(sp)
    800027ca:	0880                	add	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    800027cc:	00006517          	auipc	a0,0x6
    800027d0:	a6c50513          	add	a0,a0,-1428 # 80008238 <digits+0x1f8>
    800027d4:	ffffe097          	auipc	ra,0xffffe
    800027d8:	db2080e7          	jalr	-590(ra) # 80000586 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800027dc:	0022f497          	auipc	s1,0x22f
    800027e0:	91c48493          	add	s1,s1,-1764 # 802310f8 <proc+0x158>
    800027e4:	00235917          	auipc	s2,0x235
    800027e8:	b1490913          	add	s2,s2,-1260 # 802372f8 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027ec:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800027ee:	00006997          	auipc	s3,0x6
    800027f2:	aba98993          	add	s3,s3,-1350 # 800082a8 <digits+0x268>
    printf("%d %s %s", p->pid, state, p->name);
    800027f6:	00006a97          	auipc	s5,0x6
    800027fa:	abaa8a93          	add	s5,s5,-1350 # 800082b0 <digits+0x270>
    printf("\n");
    800027fe:	00006a17          	auipc	s4,0x6
    80002802:	a3aa0a13          	add	s4,s4,-1478 # 80008238 <digits+0x1f8>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002806:	00006b97          	auipc	s7,0x6
    8000280a:	aeab8b93          	add	s7,s7,-1302 # 800082f0 <states.0>
    8000280e:	a00d                	j	80002830 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002810:	ed86a583          	lw	a1,-296(a3)
    80002814:	8556                	mv	a0,s5
    80002816:	ffffe097          	auipc	ra,0xffffe
    8000281a:	d70080e7          	jalr	-656(ra) # 80000586 <printf>
    printf("\n");
    8000281e:	8552                	mv	a0,s4
    80002820:	ffffe097          	auipc	ra,0xffffe
    80002824:	d66080e7          	jalr	-666(ra) # 80000586 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002828:	18848493          	add	s1,s1,392
    8000282c:	03248263          	beq	s1,s2,80002850 <procdump+0x9a>
    if (p->state == UNUSED)
    80002830:	86a6                	mv	a3,s1
    80002832:	ec04a783          	lw	a5,-320(s1)
    80002836:	dbed                	beqz	a5,80002828 <procdump+0x72>
      state = "???";
    80002838:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000283a:	fcfb6be3          	bltu	s6,a5,80002810 <procdump+0x5a>
    8000283e:	02079713          	sll	a4,a5,0x20
    80002842:	01d75793          	srl	a5,a4,0x1d
    80002846:	97de                	add	a5,a5,s7
    80002848:	6390                	ld	a2,0(a5)
    8000284a:	f279                	bnez	a2,80002810 <procdump+0x5a>
      state = "???";
    8000284c:	864e                	mv	a2,s3
    8000284e:	b7c9                	j	80002810 <procdump+0x5a>
  }
}
    80002850:	60a6                	ld	ra,72(sp)
    80002852:	6406                	ld	s0,64(sp)
    80002854:	74e2                	ld	s1,56(sp)
    80002856:	7942                	ld	s2,48(sp)
    80002858:	79a2                	ld	s3,40(sp)
    8000285a:	7a02                	ld	s4,32(sp)
    8000285c:	6ae2                	ld	s5,24(sp)
    8000285e:	6b42                	ld	s6,16(sp)
    80002860:	6ba2                	ld	s7,8(sp)
    80002862:	6161                	add	sp,sp,80
    80002864:	8082                	ret

0000000080002866 <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    80002866:	711d                	add	sp,sp,-96
    80002868:	ec86                	sd	ra,88(sp)
    8000286a:	e8a2                	sd	s0,80(sp)
    8000286c:	e4a6                	sd	s1,72(sp)
    8000286e:	e0ca                	sd	s2,64(sp)
    80002870:	fc4e                	sd	s3,56(sp)
    80002872:	f852                	sd	s4,48(sp)
    80002874:	f456                	sd	s5,40(sp)
    80002876:	f05a                	sd	s6,32(sp)
    80002878:	ec5e                	sd	s7,24(sp)
    8000287a:	e862                	sd	s8,16(sp)
    8000287c:	e466                	sd	s9,8(sp)
    8000287e:	e06a                	sd	s10,0(sp)
    80002880:	1080                	add	s0,sp,96
    80002882:	8b2a                	mv	s6,a0
    80002884:	8bae                	mv	s7,a1
    80002886:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002888:	fffff097          	auipc	ra,0xfffff
    8000288c:	1ba080e7          	jalr	442(ra) # 80001a42 <myproc>
    80002890:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002892:	0022e517          	auipc	a0,0x22e
    80002896:	2f650513          	add	a0,a0,758 # 80230b88 <wait_lock>
    8000289a:	ffffe097          	auipc	ra,0xffffe
    8000289e:	402080e7          	jalr	1026(ra) # 80000c9c <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    800028a2:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    800028a4:	4a15                	li	s4,5
        havekids = 1;
    800028a6:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    800028a8:	00235997          	auipc	s3,0x235
    800028ac:	8f898993          	add	s3,s3,-1800 # 802371a0 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    800028b0:	0022ed17          	auipc	s10,0x22e
    800028b4:	2d8d0d13          	add	s10,s10,728 # 80230b88 <wait_lock>
    800028b8:	a8e9                	j	80002992 <waitx+0x12c>
          pid = np->pid;
    800028ba:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    800028be:	1684a783          	lw	a5,360(s1)
    800028c2:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    800028c6:	16c4a703          	lw	a4,364(s1)
    800028ca:	9f3d                	addw	a4,a4,a5
    800028cc:	1704a783          	lw	a5,368(s1)
    800028d0:	9f99                	subw	a5,a5,a4
    800028d2:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800028d6:	000b0e63          	beqz	s6,800028f2 <waitx+0x8c>
    800028da:	4691                	li	a3,4
    800028dc:	02c48613          	add	a2,s1,44
    800028e0:	85da                	mv	a1,s6
    800028e2:	05093503          	ld	a0,80(s2)
    800028e6:	fffff097          	auipc	ra,0xfffff
    800028ea:	e1c080e7          	jalr	-484(ra) # 80001702 <copyout>
    800028ee:	04054363          	bltz	a0,80002934 <waitx+0xce>
          freeproc(np);
    800028f2:	8526                	mv	a0,s1
    800028f4:	fffff097          	auipc	ra,0xfffff
    800028f8:	300080e7          	jalr	768(ra) # 80001bf4 <freeproc>
          release(&np->lock);
    800028fc:	8526                	mv	a0,s1
    800028fe:	ffffe097          	auipc	ra,0xffffe
    80002902:	452080e7          	jalr	1106(ra) # 80000d50 <release>
          release(&wait_lock);
    80002906:	0022e517          	auipc	a0,0x22e
    8000290a:	28250513          	add	a0,a0,642 # 80230b88 <wait_lock>
    8000290e:	ffffe097          	auipc	ra,0xffffe
    80002912:	442080e7          	jalr	1090(ra) # 80000d50 <release>
  }
}
    80002916:	854e                	mv	a0,s3
    80002918:	60e6                	ld	ra,88(sp)
    8000291a:	6446                	ld	s0,80(sp)
    8000291c:	64a6                	ld	s1,72(sp)
    8000291e:	6906                	ld	s2,64(sp)
    80002920:	79e2                	ld	s3,56(sp)
    80002922:	7a42                	ld	s4,48(sp)
    80002924:	7aa2                	ld	s5,40(sp)
    80002926:	7b02                	ld	s6,32(sp)
    80002928:	6be2                	ld	s7,24(sp)
    8000292a:	6c42                	ld	s8,16(sp)
    8000292c:	6ca2                	ld	s9,8(sp)
    8000292e:	6d02                	ld	s10,0(sp)
    80002930:	6125                	add	sp,sp,96
    80002932:	8082                	ret
            release(&np->lock);
    80002934:	8526                	mv	a0,s1
    80002936:	ffffe097          	auipc	ra,0xffffe
    8000293a:	41a080e7          	jalr	1050(ra) # 80000d50 <release>
            release(&wait_lock);
    8000293e:	0022e517          	auipc	a0,0x22e
    80002942:	24a50513          	add	a0,a0,586 # 80230b88 <wait_lock>
    80002946:	ffffe097          	auipc	ra,0xffffe
    8000294a:	40a080e7          	jalr	1034(ra) # 80000d50 <release>
            return -1;
    8000294e:	59fd                	li	s3,-1
    80002950:	b7d9                	j	80002916 <waitx+0xb0>
    for (np = proc; np < &proc[NPROC]; np++)
    80002952:	18848493          	add	s1,s1,392
    80002956:	03348463          	beq	s1,s3,8000297e <waitx+0x118>
      if (np->parent == p)
    8000295a:	7c9c                	ld	a5,56(s1)
    8000295c:	ff279be3          	bne	a5,s2,80002952 <waitx+0xec>
        acquire(&np->lock);
    80002960:	8526                	mv	a0,s1
    80002962:	ffffe097          	auipc	ra,0xffffe
    80002966:	33a080e7          	jalr	826(ra) # 80000c9c <acquire>
        if (np->state == ZOMBIE)
    8000296a:	4c9c                	lw	a5,24(s1)
    8000296c:	f54787e3          	beq	a5,s4,800028ba <waitx+0x54>
        release(&np->lock);
    80002970:	8526                	mv	a0,s1
    80002972:	ffffe097          	auipc	ra,0xffffe
    80002976:	3de080e7          	jalr	990(ra) # 80000d50 <release>
        havekids = 1;
    8000297a:	8756                	mv	a4,s5
    8000297c:	bfd9                	j	80002952 <waitx+0xec>
    if (!havekids || p->killed)
    8000297e:	c305                	beqz	a4,8000299e <waitx+0x138>
    80002980:	02892783          	lw	a5,40(s2)
    80002984:	ef89                	bnez	a5,8000299e <waitx+0x138>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002986:	85ea                	mv	a1,s10
    80002988:	854a                	mv	a0,s2
    8000298a:	00000097          	auipc	ra,0x0
    8000298e:	96c080e7          	jalr	-1684(ra) # 800022f6 <sleep>
    havekids = 0;
    80002992:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002994:	0022e497          	auipc	s1,0x22e
    80002998:	60c48493          	add	s1,s1,1548 # 80230fa0 <proc>
    8000299c:	bf7d                	j	8000295a <waitx+0xf4>
      release(&wait_lock);
    8000299e:	0022e517          	auipc	a0,0x22e
    800029a2:	1ea50513          	add	a0,a0,490 # 80230b88 <wait_lock>
    800029a6:	ffffe097          	auipc	ra,0xffffe
    800029aa:	3aa080e7          	jalr	938(ra) # 80000d50 <release>
      return -1;
    800029ae:	59fd                	li	s3,-1
    800029b0:	b79d                	j	80002916 <waitx+0xb0>

00000000800029b2 <update_time>:

void update_time()
{
    800029b2:	7179                	add	sp,sp,-48
    800029b4:	f406                	sd	ra,40(sp)
    800029b6:	f022                	sd	s0,32(sp)
    800029b8:	ec26                	sd	s1,24(sp)
    800029ba:	e84a                	sd	s2,16(sp)
    800029bc:	e44e                	sd	s3,8(sp)
    800029be:	1800                	add	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    800029c0:	0022e497          	auipc	s1,0x22e
    800029c4:	5e048493          	add	s1,s1,1504 # 80230fa0 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    800029c8:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    800029ca:	00234917          	auipc	s2,0x234
    800029ce:	7d690913          	add	s2,s2,2006 # 802371a0 <tickslock>
    800029d2:	a811                	j	800029e6 <update_time+0x34>
    {
      p->rtime++;
    }
    release(&p->lock);
    800029d4:	8526                	mv	a0,s1
    800029d6:	ffffe097          	auipc	ra,0xffffe
    800029da:	37a080e7          	jalr	890(ra) # 80000d50 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800029de:	18848493          	add	s1,s1,392
    800029e2:	03248063          	beq	s1,s2,80002a02 <update_time+0x50>
    acquire(&p->lock);
    800029e6:	8526                	mv	a0,s1
    800029e8:	ffffe097          	auipc	ra,0xffffe
    800029ec:	2b4080e7          	jalr	692(ra) # 80000c9c <acquire>
    if (p->state == RUNNING)
    800029f0:	4c9c                	lw	a5,24(s1)
    800029f2:	ff3791e3          	bne	a5,s3,800029d4 <update_time+0x22>
      p->rtime++;
    800029f6:	1684a783          	lw	a5,360(s1)
    800029fa:	2785                	addw	a5,a5,1
    800029fc:	16f4a423          	sw	a5,360(s1)
    80002a00:	bfd1                	j	800029d4 <update_time+0x22>
  }
    80002a02:	70a2                	ld	ra,40(sp)
    80002a04:	7402                	ld	s0,32(sp)
    80002a06:	64e2                	ld	s1,24(sp)
    80002a08:	6942                	ld	s2,16(sp)
    80002a0a:	69a2                	ld	s3,8(sp)
    80002a0c:	6145                	add	sp,sp,48
    80002a0e:	8082                	ret

0000000080002a10 <swtch>:
    80002a10:	00153023          	sd	ra,0(a0)
    80002a14:	00253423          	sd	sp,8(a0)
    80002a18:	e900                	sd	s0,16(a0)
    80002a1a:	ed04                	sd	s1,24(a0)
    80002a1c:	03253023          	sd	s2,32(a0)
    80002a20:	03353423          	sd	s3,40(a0)
    80002a24:	03453823          	sd	s4,48(a0)
    80002a28:	03553c23          	sd	s5,56(a0)
    80002a2c:	05653023          	sd	s6,64(a0)
    80002a30:	05753423          	sd	s7,72(a0)
    80002a34:	05853823          	sd	s8,80(a0)
    80002a38:	05953c23          	sd	s9,88(a0)
    80002a3c:	07a53023          	sd	s10,96(a0)
    80002a40:	07b53423          	sd	s11,104(a0)
    80002a44:	0005b083          	ld	ra,0(a1)
    80002a48:	0085b103          	ld	sp,8(a1)
    80002a4c:	6980                	ld	s0,16(a1)
    80002a4e:	6d84                	ld	s1,24(a1)
    80002a50:	0205b903          	ld	s2,32(a1)
    80002a54:	0285b983          	ld	s3,40(a1)
    80002a58:	0305ba03          	ld	s4,48(a1)
    80002a5c:	0385ba83          	ld	s5,56(a1)
    80002a60:	0405bb03          	ld	s6,64(a1)
    80002a64:	0485bb83          	ld	s7,72(a1)
    80002a68:	0505bc03          	ld	s8,80(a1)
    80002a6c:	0585bc83          	ld	s9,88(a1)
    80002a70:	0605bd03          	ld	s10,96(a1)
    80002a74:	0685bd83          	ld	s11,104(a1)
    80002a78:	8082                	ret

0000000080002a7a <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002a7a:	1141                	add	sp,sp,-16
    80002a7c:	e406                	sd	ra,8(sp)
    80002a7e:	e022                	sd	s0,0(sp)
    80002a80:	0800                	add	s0,sp,16
  initlock(&tickslock, "time");
    80002a82:	00006597          	auipc	a1,0x6
    80002a86:	89e58593          	add	a1,a1,-1890 # 80008320 <states.0+0x30>
    80002a8a:	00234517          	auipc	a0,0x234
    80002a8e:	71650513          	add	a0,a0,1814 # 802371a0 <tickslock>
    80002a92:	ffffe097          	auipc	ra,0xffffe
    80002a96:	17a080e7          	jalr	378(ra) # 80000c0c <initlock>
}
    80002a9a:	60a2                	ld	ra,8(sp)
    80002a9c:	6402                	ld	s0,0(sp)
    80002a9e:	0141                	add	sp,sp,16
    80002aa0:	8082                	ret

0000000080002aa2 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002aa2:	1141                	add	sp,sp,-16
    80002aa4:	e422                	sd	s0,8(sp)
    80002aa6:	0800                	add	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002aa8:	00003797          	auipc	a5,0x3
    80002aac:	5b878793          	add	a5,a5,1464 # 80006060 <kernelvec>
    80002ab0:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002ab4:	6422                	ld	s0,8(sp)
    80002ab6:	0141                	add	sp,sp,16
    80002ab8:	8082                	ret

0000000080002aba <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002aba:	1141                	add	sp,sp,-16
    80002abc:	e406                	sd	ra,8(sp)
    80002abe:	e022                	sd	s0,0(sp)
    80002ac0:	0800                	add	s0,sp,16
  struct proc *p = myproc();
    80002ac2:	fffff097          	auipc	ra,0xfffff
    80002ac6:	f80080e7          	jalr	-128(ra) # 80001a42 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aca:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002ace:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ad0:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002ad4:	00004697          	auipc	a3,0x4
    80002ad8:	52c68693          	add	a3,a3,1324 # 80007000 <_trampoline>
    80002adc:	00004717          	auipc	a4,0x4
    80002ae0:	52470713          	add	a4,a4,1316 # 80007000 <_trampoline>
    80002ae4:	8f15                	sub	a4,a4,a3
    80002ae6:	040007b7          	lui	a5,0x4000
    80002aea:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002aec:	07b2                	sll	a5,a5,0xc
    80002aee:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002af0:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002af4:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002af6:	18002673          	csrr	a2,satp
    80002afa:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002afc:	6d30                	ld	a2,88(a0)
    80002afe:	6138                	ld	a4,64(a0)
    80002b00:	6585                	lui	a1,0x1
    80002b02:	972e                	add	a4,a4,a1
    80002b04:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002b06:	6d38                	ld	a4,88(a0)
    80002b08:	00000617          	auipc	a2,0x0
    80002b0c:	14260613          	add	a2,a2,322 # 80002c4a <usertrap>
    80002b10:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002b12:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002b14:	8612                	mv	a2,tp
    80002b16:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b18:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002b1c:	eff77713          	and	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002b20:	02076713          	or	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b24:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002b28:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b2a:	6f18                	ld	a4,24(a4)
    80002b2c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002b30:	6928                	ld	a0,80(a0)
    80002b32:	8131                	srl	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002b34:	00004717          	auipc	a4,0x4
    80002b38:	56870713          	add	a4,a4,1384 # 8000709c <userret>
    80002b3c:	8f15                	sub	a4,a4,a3
    80002b3e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002b40:	577d                	li	a4,-1
    80002b42:	177e                	sll	a4,a4,0x3f
    80002b44:	8d59                	or	a0,a0,a4
    80002b46:	9782                	jalr	a5
}
    80002b48:	60a2                	ld	ra,8(sp)
    80002b4a:	6402                	ld	s0,0(sp)
    80002b4c:	0141                	add	sp,sp,16
    80002b4e:	8082                	ret

0000000080002b50 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002b50:	1101                	add	sp,sp,-32
    80002b52:	ec06                	sd	ra,24(sp)
    80002b54:	e822                	sd	s0,16(sp)
    80002b56:	e426                	sd	s1,8(sp)
    80002b58:	e04a                	sd	s2,0(sp)
    80002b5a:	1000                	add	s0,sp,32
  acquire(&tickslock);
    80002b5c:	00234917          	auipc	s2,0x234
    80002b60:	64490913          	add	s2,s2,1604 # 802371a0 <tickslock>
    80002b64:	854a                	mv	a0,s2
    80002b66:	ffffe097          	auipc	ra,0xffffe
    80002b6a:	136080e7          	jalr	310(ra) # 80000c9c <acquire>
  ticks++;
    80002b6e:	00006497          	auipc	s1,0x6
    80002b72:	d9248493          	add	s1,s1,-622 # 80008900 <ticks>
    80002b76:	409c                	lw	a5,0(s1)
    80002b78:	2785                	addw	a5,a5,1
    80002b7a:	c09c                	sw	a5,0(s1)
  update_time();
    80002b7c:	00000097          	auipc	ra,0x0
    80002b80:	e36080e7          	jalr	-458(ra) # 800029b2 <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80002b84:	8526                	mv	a0,s1
    80002b86:	fffff097          	auipc	ra,0xfffff
    80002b8a:	7d4080e7          	jalr	2004(ra) # 8000235a <wakeup>
  release(&tickslock);
    80002b8e:	854a                	mv	a0,s2
    80002b90:	ffffe097          	auipc	ra,0xffffe
    80002b94:	1c0080e7          	jalr	448(ra) # 80000d50 <release>
}
    80002b98:	60e2                	ld	ra,24(sp)
    80002b9a:	6442                	ld	s0,16(sp)
    80002b9c:	64a2                	ld	s1,8(sp)
    80002b9e:	6902                	ld	s2,0(sp)
    80002ba0:	6105                	add	sp,sp,32
    80002ba2:	8082                	ret

0000000080002ba4 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ba4:	142027f3          	csrr	a5,scause

    return 2;
  }
  else
  {
    return 0;
    80002ba8:	4501                	li	a0,0
  if ((scause & 0x8000000000000000L) &&
    80002baa:	0807df63          	bgez	a5,80002c48 <devintr+0xa4>
{
    80002bae:	1101                	add	sp,sp,-32
    80002bb0:	ec06                	sd	ra,24(sp)
    80002bb2:	e822                	sd	s0,16(sp)
    80002bb4:	e426                	sd	s1,8(sp)
    80002bb6:	1000                	add	s0,sp,32
      (scause & 0xff) == 9)
    80002bb8:	0ff7f713          	zext.b	a4,a5
  if ((scause & 0x8000000000000000L) &&
    80002bbc:	46a5                	li	a3,9
    80002bbe:	00d70d63          	beq	a4,a3,80002bd8 <devintr+0x34>
  else if (scause == 0x8000000000000001L)
    80002bc2:	577d                	li	a4,-1
    80002bc4:	177e                	sll	a4,a4,0x3f
    80002bc6:	0705                	add	a4,a4,1
    return 0;
    80002bc8:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002bca:	04e78e63          	beq	a5,a4,80002c26 <devintr+0x82>
  }
}
    80002bce:	60e2                	ld	ra,24(sp)
    80002bd0:	6442                	ld	s0,16(sp)
    80002bd2:	64a2                	ld	s1,8(sp)
    80002bd4:	6105                	add	sp,sp,32
    80002bd6:	8082                	ret
    int irq = plic_claim();
    80002bd8:	00003097          	auipc	ra,0x3
    80002bdc:	590080e7          	jalr	1424(ra) # 80006168 <plic_claim>
    80002be0:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002be2:	47a9                	li	a5,10
    80002be4:	02f50763          	beq	a0,a5,80002c12 <devintr+0x6e>
    else if (irq == VIRTIO0_IRQ)
    80002be8:	4785                	li	a5,1
    80002bea:	02f50963          	beq	a0,a5,80002c1c <devintr+0x78>
    return 1;
    80002bee:	4505                	li	a0,1
    else if (irq)
    80002bf0:	dcf9                	beqz	s1,80002bce <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    80002bf2:	85a6                	mv	a1,s1
    80002bf4:	00005517          	auipc	a0,0x5
    80002bf8:	73450513          	add	a0,a0,1844 # 80008328 <states.0+0x38>
    80002bfc:	ffffe097          	auipc	ra,0xffffe
    80002c00:	98a080e7          	jalr	-1654(ra) # 80000586 <printf>
      plic_complete(irq);
    80002c04:	8526                	mv	a0,s1
    80002c06:	00003097          	auipc	ra,0x3
    80002c0a:	586080e7          	jalr	1414(ra) # 8000618c <plic_complete>
    return 1;
    80002c0e:	4505                	li	a0,1
    80002c10:	bf7d                	j	80002bce <devintr+0x2a>
      uartintr();
    80002c12:	ffffe097          	auipc	ra,0xffffe
    80002c16:	d82080e7          	jalr	-638(ra) # 80000994 <uartintr>
    if (irq)
    80002c1a:	b7ed                	j	80002c04 <devintr+0x60>
      virtio_disk_intr();
    80002c1c:	00004097          	auipc	ra,0x4
    80002c20:	a36080e7          	jalr	-1482(ra) # 80006652 <virtio_disk_intr>
    if (irq)
    80002c24:	b7c5                	j	80002c04 <devintr+0x60>
    if (cpuid() == 0)
    80002c26:	fffff097          	auipc	ra,0xfffff
    80002c2a:	df0080e7          	jalr	-528(ra) # 80001a16 <cpuid>
    80002c2e:	c901                	beqz	a0,80002c3e <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002c30:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002c34:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002c36:	14479073          	csrw	sip,a5
    return 2;
    80002c3a:	4509                	li	a0,2
    80002c3c:	bf49                	j	80002bce <devintr+0x2a>
      clockintr();
    80002c3e:	00000097          	auipc	ra,0x0
    80002c42:	f12080e7          	jalr	-238(ra) # 80002b50 <clockintr>
    80002c46:	b7ed                	j	80002c30 <devintr+0x8c>
}
    80002c48:	8082                	ret

0000000080002c4a <usertrap>:
{
    80002c4a:	7179                	add	sp,sp,-48
    80002c4c:	f406                	sd	ra,40(sp)
    80002c4e:	f022                	sd	s0,32(sp)
    80002c50:	ec26                	sd	s1,24(sp)
    80002c52:	e84a                	sd	s2,16(sp)
    80002c54:	e44e                	sd	s3,8(sp)
    80002c56:	e052                	sd	s4,0(sp)
    80002c58:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c5a:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002c5e:	1007f793          	and	a5,a5,256
    80002c62:	e3c5                	bnez	a5,80002d02 <usertrap+0xb8>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c64:	00003797          	auipc	a5,0x3
    80002c68:	3fc78793          	add	a5,a5,1020 # 80006060 <kernelvec>
    80002c6c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002c70:	fffff097          	auipc	ra,0xfffff
    80002c74:	dd2080e7          	jalr	-558(ra) # 80001a42 <myproc>
    80002c78:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002c7a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c7c:	14102773          	csrr	a4,sepc
    80002c80:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c82:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002c86:	47a1                	li	a5,8
    80002c88:	08f70563          	beq	a4,a5,80002d12 <usertrap+0xc8>
  else if ((which_dev = devintr()) != 0)
    80002c8c:	00000097          	auipc	ra,0x0
    80002c90:	f18080e7          	jalr	-232(ra) # 80002ba4 <devintr>
    80002c94:	892a                	mv	s2,a0
    80002c96:	10051663          	bnez	a0,80002da2 <usertrap+0x158>
    80002c9a:	14202773          	csrr	a4,scause
    if (r_scause() == 0xf){ // Page write fault
    80002c9e:	47bd                	li	a5,15
    80002ca0:	0cf71463          	bne	a4,a5,80002d68 <usertrap+0x11e>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ca4:	143025f3          	csrr	a1,stval
      if (va < MAXVA){
    80002ca8:	57fd                	li	a5,-1
    80002caa:	83e9                	srl	a5,a5,0x1a
    80002cac:	08b7e663          	bltu	a5,a1,80002d38 <usertrap+0xee>
        pte_t * pte =walk(p->pagetable, va, 0);
    80002cb0:	4601                	li	a2,0
    80002cb2:	68a8                	ld	a0,80(s1)
    80002cb4:	ffffe097          	auipc	ra,0xffffe
    80002cb8:	3c6080e7          	jalr	966(ra) # 8000107a <walk>
    80002cbc:	892a                	mv	s2,a0
        if ((*pte & PTE_U) != 0 &&  (*pte & PTE_V) !=0 ){
    80002cbe:	00053983          	ld	s3,0(a0)
    80002cc2:	0119f713          	and	a4,s3,17
    80002cc6:	47c5                	li	a5,17
    80002cc8:	06f71863          	bne	a4,a5,80002d38 <usertrap+0xee>
          char* mem = kalloc();
    80002ccc:	ffffe097          	auipc	ra,0xffffe
    80002cd0:	e82080e7          	jalr	-382(ra) # 80000b4e <kalloc>
    80002cd4:	8a2a                	mv	s4,a0
          uint64 pa = PTE2PA(*pte);
    80002cd6:	00a9d993          	srl	s3,s3,0xa
    80002cda:	09b2                	sll	s3,s3,0xc
          memmove(mem, (char*)pa, PGSIZE);
    80002cdc:	6605                	lui	a2,0x1
    80002cde:	85ce                	mv	a1,s3
    80002ce0:	ffffe097          	auipc	ra,0xffffe
    80002ce4:	114080e7          	jalr	276(ra) # 80000df4 <memmove>
          *pte = PA2PTE((uint64)mem);
    80002ce8:	00ca5793          	srl	a5,s4,0xc
    80002cec:	07aa                	sll	a5,a5,0xa
          *pte |= PTE_V | PTE_U| PTE_R| PTE_W | PTE_X;
    80002cee:	01f7e793          	or	a5,a5,31
    80002cf2:	00f93023          	sd	a5,0(s2)
          kfree((char*)pa);
    80002cf6:	854e                	mv	a0,s3
    80002cf8:	ffffe097          	auipc	ra,0xffffe
    80002cfc:	cec080e7          	jalr	-788(ra) # 800009e4 <kfree>
    80002d00:	a825                	j	80002d38 <usertrap+0xee>
    panic("usertrap: not from user mode");
    80002d02:	00005517          	auipc	a0,0x5
    80002d06:	64650513          	add	a0,a0,1606 # 80008348 <states.0+0x58>
    80002d0a:	ffffe097          	auipc	ra,0xffffe
    80002d0e:	832080e7          	jalr	-1998(ra) # 8000053c <panic>
    if (killed(p))
    80002d12:	00000097          	auipc	ra,0x0
    80002d16:	898080e7          	jalr	-1896(ra) # 800025aa <killed>
    80002d1a:	e129                	bnez	a0,80002d5c <usertrap+0x112>
    p->trapframe->epc += 4;
    80002d1c:	6cb8                	ld	a4,88(s1)
    80002d1e:	6f1c                	ld	a5,24(a4)
    80002d20:	0791                	add	a5,a5,4
    80002d22:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d24:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002d28:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d2c:	10079073          	csrw	sstatus,a5
    syscall();
    80002d30:	00000097          	auipc	ra,0x0
    80002d34:	2e6080e7          	jalr	742(ra) # 80003016 <syscall>
  if (killed(p))
    80002d38:	8526                	mv	a0,s1
    80002d3a:	00000097          	auipc	ra,0x0
    80002d3e:	870080e7          	jalr	-1936(ra) # 800025aa <killed>
    80002d42:	e53d                	bnez	a0,80002db0 <usertrap+0x166>
  usertrapret();
    80002d44:	00000097          	auipc	ra,0x0
    80002d48:	d76080e7          	jalr	-650(ra) # 80002aba <usertrapret>
}
    80002d4c:	70a2                	ld	ra,40(sp)
    80002d4e:	7402                	ld	s0,32(sp)
    80002d50:	64e2                	ld	s1,24(sp)
    80002d52:	6942                	ld	s2,16(sp)
    80002d54:	69a2                	ld	s3,8(sp)
    80002d56:	6a02                	ld	s4,0(sp)
    80002d58:	6145                	add	sp,sp,48
    80002d5a:	8082                	ret
      exit(-1);
    80002d5c:	557d                	li	a0,-1
    80002d5e:	fffff097          	auipc	ra,0xfffff
    80002d62:	6cc080e7          	jalr	1740(ra) # 8000242a <exit>
    80002d66:	bf5d                	j	80002d1c <usertrap+0xd2>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d68:	142025f3          	csrr	a1,scause
      printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002d6c:	5890                	lw	a2,48(s1)
    80002d6e:	00005517          	auipc	a0,0x5
    80002d72:	5fa50513          	add	a0,a0,1530 # 80008368 <states.0+0x78>
    80002d76:	ffffe097          	auipc	ra,0xffffe
    80002d7a:	810080e7          	jalr	-2032(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d7e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d82:	14302673          	csrr	a2,stval
      printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d86:	00005517          	auipc	a0,0x5
    80002d8a:	61250513          	add	a0,a0,1554 # 80008398 <states.0+0xa8>
    80002d8e:	ffffd097          	auipc	ra,0xffffd
    80002d92:	7f8080e7          	jalr	2040(ra) # 80000586 <printf>
      setkilled(p);
    80002d96:	8526                	mv	a0,s1
    80002d98:	fffff097          	auipc	ra,0xfffff
    80002d9c:	7e6080e7          	jalr	2022(ra) # 8000257e <setkilled>
    80002da0:	bf61                	j	80002d38 <usertrap+0xee>
  if (killed(p))
    80002da2:	8526                	mv	a0,s1
    80002da4:	00000097          	auipc	ra,0x0
    80002da8:	806080e7          	jalr	-2042(ra) # 800025aa <killed>
    80002dac:	c901                	beqz	a0,80002dbc <usertrap+0x172>
    80002dae:	a011                	j	80002db2 <usertrap+0x168>
    80002db0:	4901                	li	s2,0
    exit(-1);
    80002db2:	557d                	li	a0,-1
    80002db4:	fffff097          	auipc	ra,0xfffff
    80002db8:	676080e7          	jalr	1654(ra) # 8000242a <exit>
  if (which_dev == 2)
    80002dbc:	4789                	li	a5,2
    80002dbe:	f8f913e3          	bne	s2,a5,80002d44 <usertrap+0xfa>
    yield();
    80002dc2:	fffff097          	auipc	ra,0xfffff
    80002dc6:	4f8080e7          	jalr	1272(ra) # 800022ba <yield>
    80002dca:	bfad                	j	80002d44 <usertrap+0xfa>

0000000080002dcc <kerneltrap>:
{
    80002dcc:	7179                	add	sp,sp,-48
    80002dce:	f406                	sd	ra,40(sp)
    80002dd0:	f022                	sd	s0,32(sp)
    80002dd2:	ec26                	sd	s1,24(sp)
    80002dd4:	e84a                	sd	s2,16(sp)
    80002dd6:	e44e                	sd	s3,8(sp)
    80002dd8:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002dda:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002dde:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002de2:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002de6:	1004f793          	and	a5,s1,256
    80002dea:	cb85                	beqz	a5,80002e1a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002dec:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002df0:	8b89                	and	a5,a5,2
  if (intr_get() != 0)
    80002df2:	ef85                	bnez	a5,80002e2a <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002df4:	00000097          	auipc	ra,0x0
    80002df8:	db0080e7          	jalr	-592(ra) # 80002ba4 <devintr>
    80002dfc:	cd1d                	beqz	a0,80002e3a <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002dfe:	4789                	li	a5,2
    80002e00:	06f50a63          	beq	a0,a5,80002e74 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e04:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e08:	10049073          	csrw	sstatus,s1
}
    80002e0c:	70a2                	ld	ra,40(sp)
    80002e0e:	7402                	ld	s0,32(sp)
    80002e10:	64e2                	ld	s1,24(sp)
    80002e12:	6942                	ld	s2,16(sp)
    80002e14:	69a2                	ld	s3,8(sp)
    80002e16:	6145                	add	sp,sp,48
    80002e18:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002e1a:	00005517          	auipc	a0,0x5
    80002e1e:	59e50513          	add	a0,a0,1438 # 800083b8 <states.0+0xc8>
    80002e22:	ffffd097          	auipc	ra,0xffffd
    80002e26:	71a080e7          	jalr	1818(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    80002e2a:	00005517          	auipc	a0,0x5
    80002e2e:	5b650513          	add	a0,a0,1462 # 800083e0 <states.0+0xf0>
    80002e32:	ffffd097          	auipc	ra,0xffffd
    80002e36:	70a080e7          	jalr	1802(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    80002e3a:	85ce                	mv	a1,s3
    80002e3c:	00005517          	auipc	a0,0x5
    80002e40:	5c450513          	add	a0,a0,1476 # 80008400 <states.0+0x110>
    80002e44:	ffffd097          	auipc	ra,0xffffd
    80002e48:	742080e7          	jalr	1858(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e4c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e50:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e54:	00005517          	auipc	a0,0x5
    80002e58:	5bc50513          	add	a0,a0,1468 # 80008410 <states.0+0x120>
    80002e5c:	ffffd097          	auipc	ra,0xffffd
    80002e60:	72a080e7          	jalr	1834(ra) # 80000586 <printf>
    panic("kerneltrap");
    80002e64:	00005517          	auipc	a0,0x5
    80002e68:	5c450513          	add	a0,a0,1476 # 80008428 <states.0+0x138>
    80002e6c:	ffffd097          	auipc	ra,0xffffd
    80002e70:	6d0080e7          	jalr	1744(ra) # 8000053c <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e74:	fffff097          	auipc	ra,0xfffff
    80002e78:	bce080e7          	jalr	-1074(ra) # 80001a42 <myproc>
    80002e7c:	d541                	beqz	a0,80002e04 <kerneltrap+0x38>
    80002e7e:	fffff097          	auipc	ra,0xfffff
    80002e82:	bc4080e7          	jalr	-1084(ra) # 80001a42 <myproc>
    80002e86:	4d18                	lw	a4,24(a0)
    80002e88:	4791                	li	a5,4
    80002e8a:	f6f71de3          	bne	a4,a5,80002e04 <kerneltrap+0x38>
    yield();
    80002e8e:	fffff097          	auipc	ra,0xfffff
    80002e92:	42c080e7          	jalr	1068(ra) # 800022ba <yield>
    80002e96:	b7bd                	j	80002e04 <kerneltrap+0x38>

0000000080002e98 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002e98:	1101                	add	sp,sp,-32
    80002e9a:	ec06                	sd	ra,24(sp)
    80002e9c:	e822                	sd	s0,16(sp)
    80002e9e:	e426                	sd	s1,8(sp)
    80002ea0:	1000                	add	s0,sp,32
    80002ea2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ea4:	fffff097          	auipc	ra,0xfffff
    80002ea8:	b9e080e7          	jalr	-1122(ra) # 80001a42 <myproc>
  switch (n) {
    80002eac:	4795                	li	a5,5
    80002eae:	0497e163          	bltu	a5,s1,80002ef0 <argraw+0x58>
    80002eb2:	048a                	sll	s1,s1,0x2
    80002eb4:	00005717          	auipc	a4,0x5
    80002eb8:	5ac70713          	add	a4,a4,1452 # 80008460 <states.0+0x170>
    80002ebc:	94ba                	add	s1,s1,a4
    80002ebe:	409c                	lw	a5,0(s1)
    80002ec0:	97ba                	add	a5,a5,a4
    80002ec2:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002ec4:	6d3c                	ld	a5,88(a0)
    80002ec6:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ec8:	60e2                	ld	ra,24(sp)
    80002eca:	6442                	ld	s0,16(sp)
    80002ecc:	64a2                	ld	s1,8(sp)
    80002ece:	6105                	add	sp,sp,32
    80002ed0:	8082                	ret
    return p->trapframe->a1;
    80002ed2:	6d3c                	ld	a5,88(a0)
    80002ed4:	7fa8                	ld	a0,120(a5)
    80002ed6:	bfcd                	j	80002ec8 <argraw+0x30>
    return p->trapframe->a2;
    80002ed8:	6d3c                	ld	a5,88(a0)
    80002eda:	63c8                	ld	a0,128(a5)
    80002edc:	b7f5                	j	80002ec8 <argraw+0x30>
    return p->trapframe->a3;
    80002ede:	6d3c                	ld	a5,88(a0)
    80002ee0:	67c8                	ld	a0,136(a5)
    80002ee2:	b7dd                	j	80002ec8 <argraw+0x30>
    return p->trapframe->a4;
    80002ee4:	6d3c                	ld	a5,88(a0)
    80002ee6:	6bc8                	ld	a0,144(a5)
    80002ee8:	b7c5                	j	80002ec8 <argraw+0x30>
    return p->trapframe->a5;
    80002eea:	6d3c                	ld	a5,88(a0)
    80002eec:	6fc8                	ld	a0,152(a5)
    80002eee:	bfe9                	j	80002ec8 <argraw+0x30>
  panic("argraw");
    80002ef0:	00005517          	auipc	a0,0x5
    80002ef4:	54850513          	add	a0,a0,1352 # 80008438 <states.0+0x148>
    80002ef8:	ffffd097          	auipc	ra,0xffffd
    80002efc:	644080e7          	jalr	1604(ra) # 8000053c <panic>

0000000080002f00 <fetchaddr>:
{
    80002f00:	1101                	add	sp,sp,-32
    80002f02:	ec06                	sd	ra,24(sp)
    80002f04:	e822                	sd	s0,16(sp)
    80002f06:	e426                	sd	s1,8(sp)
    80002f08:	e04a                	sd	s2,0(sp)
    80002f0a:	1000                	add	s0,sp,32
    80002f0c:	84aa                	mv	s1,a0
    80002f0e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002f10:	fffff097          	auipc	ra,0xfffff
    80002f14:	b32080e7          	jalr	-1230(ra) # 80001a42 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002f18:	653c                	ld	a5,72(a0)
    80002f1a:	02f4f863          	bgeu	s1,a5,80002f4a <fetchaddr+0x4a>
    80002f1e:	00848713          	add	a4,s1,8
    80002f22:	02e7e663          	bltu	a5,a4,80002f4e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002f26:	46a1                	li	a3,8
    80002f28:	8626                	mv	a2,s1
    80002f2a:	85ca                	mv	a1,s2
    80002f2c:	6928                	ld	a0,80(a0)
    80002f2e:	fffff097          	auipc	ra,0xfffff
    80002f32:	860080e7          	jalr	-1952(ra) # 8000178e <copyin>
    80002f36:	00a03533          	snez	a0,a0
    80002f3a:	40a00533          	neg	a0,a0
}
    80002f3e:	60e2                	ld	ra,24(sp)
    80002f40:	6442                	ld	s0,16(sp)
    80002f42:	64a2                	ld	s1,8(sp)
    80002f44:	6902                	ld	s2,0(sp)
    80002f46:	6105                	add	sp,sp,32
    80002f48:	8082                	ret
    return -1;
    80002f4a:	557d                	li	a0,-1
    80002f4c:	bfcd                	j	80002f3e <fetchaddr+0x3e>
    80002f4e:	557d                	li	a0,-1
    80002f50:	b7fd                	j	80002f3e <fetchaddr+0x3e>

0000000080002f52 <fetchstr>:
{
    80002f52:	7179                	add	sp,sp,-48
    80002f54:	f406                	sd	ra,40(sp)
    80002f56:	f022                	sd	s0,32(sp)
    80002f58:	ec26                	sd	s1,24(sp)
    80002f5a:	e84a                	sd	s2,16(sp)
    80002f5c:	e44e                	sd	s3,8(sp)
    80002f5e:	1800                	add	s0,sp,48
    80002f60:	892a                	mv	s2,a0
    80002f62:	84ae                	mv	s1,a1
    80002f64:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002f66:	fffff097          	auipc	ra,0xfffff
    80002f6a:	adc080e7          	jalr	-1316(ra) # 80001a42 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002f6e:	86ce                	mv	a3,s3
    80002f70:	864a                	mv	a2,s2
    80002f72:	85a6                	mv	a1,s1
    80002f74:	6928                	ld	a0,80(a0)
    80002f76:	fffff097          	auipc	ra,0xfffff
    80002f7a:	8a6080e7          	jalr	-1882(ra) # 8000181c <copyinstr>
    80002f7e:	00054e63          	bltz	a0,80002f9a <fetchstr+0x48>
  return strlen(buf);
    80002f82:	8526                	mv	a0,s1
    80002f84:	ffffe097          	auipc	ra,0xffffe
    80002f88:	f8e080e7          	jalr	-114(ra) # 80000f12 <strlen>
}
    80002f8c:	70a2                	ld	ra,40(sp)
    80002f8e:	7402                	ld	s0,32(sp)
    80002f90:	64e2                	ld	s1,24(sp)
    80002f92:	6942                	ld	s2,16(sp)
    80002f94:	69a2                	ld	s3,8(sp)
    80002f96:	6145                	add	sp,sp,48
    80002f98:	8082                	ret
    return -1;
    80002f9a:	557d                	li	a0,-1
    80002f9c:	bfc5                	j	80002f8c <fetchstr+0x3a>

0000000080002f9e <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002f9e:	1101                	add	sp,sp,-32
    80002fa0:	ec06                	sd	ra,24(sp)
    80002fa2:	e822                	sd	s0,16(sp)
    80002fa4:	e426                	sd	s1,8(sp)
    80002fa6:	1000                	add	s0,sp,32
    80002fa8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002faa:	00000097          	auipc	ra,0x0
    80002fae:	eee080e7          	jalr	-274(ra) # 80002e98 <argraw>
    80002fb2:	c088                	sw	a0,0(s1)
}
    80002fb4:	60e2                	ld	ra,24(sp)
    80002fb6:	6442                	ld	s0,16(sp)
    80002fb8:	64a2                	ld	s1,8(sp)
    80002fba:	6105                	add	sp,sp,32
    80002fbc:	8082                	ret

0000000080002fbe <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002fbe:	1101                	add	sp,sp,-32
    80002fc0:	ec06                	sd	ra,24(sp)
    80002fc2:	e822                	sd	s0,16(sp)
    80002fc4:	e426                	sd	s1,8(sp)
    80002fc6:	1000                	add	s0,sp,32
    80002fc8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002fca:	00000097          	auipc	ra,0x0
    80002fce:	ece080e7          	jalr	-306(ra) # 80002e98 <argraw>
    80002fd2:	e088                	sd	a0,0(s1)
}
    80002fd4:	60e2                	ld	ra,24(sp)
    80002fd6:	6442                	ld	s0,16(sp)
    80002fd8:	64a2                	ld	s1,8(sp)
    80002fda:	6105                	add	sp,sp,32
    80002fdc:	8082                	ret

0000000080002fde <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002fde:	7179                	add	sp,sp,-48
    80002fe0:	f406                	sd	ra,40(sp)
    80002fe2:	f022                	sd	s0,32(sp)
    80002fe4:	ec26                	sd	s1,24(sp)
    80002fe6:	e84a                	sd	s2,16(sp)
    80002fe8:	1800                	add	s0,sp,48
    80002fea:	84ae                	mv	s1,a1
    80002fec:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002fee:	fd840593          	add	a1,s0,-40
    80002ff2:	00000097          	auipc	ra,0x0
    80002ff6:	fcc080e7          	jalr	-52(ra) # 80002fbe <argaddr>
  return fetchstr(addr, buf, max);
    80002ffa:	864a                	mv	a2,s2
    80002ffc:	85a6                	mv	a1,s1
    80002ffe:	fd843503          	ld	a0,-40(s0)
    80003002:	00000097          	auipc	ra,0x0
    80003006:	f50080e7          	jalr	-176(ra) # 80002f52 <fetchstr>
}
    8000300a:	70a2                	ld	ra,40(sp)
    8000300c:	7402                	ld	s0,32(sp)
    8000300e:	64e2                	ld	s1,24(sp)
    80003010:	6942                	ld	s2,16(sp)
    80003012:	6145                	add	sp,sp,48
    80003014:	8082                	ret

0000000080003016 <syscall>:
[SYS_setpriority] sys_setpriority,
};

void
syscall(void)
{
    80003016:	1101                	add	sp,sp,-32
    80003018:	ec06                	sd	ra,24(sp)
    8000301a:	e822                	sd	s0,16(sp)
    8000301c:	e426                	sd	s1,8(sp)
    8000301e:	e04a                	sd	s2,0(sp)
    80003020:	1000                	add	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003022:	fffff097          	auipc	ra,0xfffff
    80003026:	a20080e7          	jalr	-1504(ra) # 80001a42 <myproc>
    8000302a:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000302c:	05853903          	ld	s2,88(a0)
    80003030:	0a893783          	ld	a5,168(s2)
    80003034:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003038:	37fd                	addw	a5,a5,-1
    8000303a:	475d                	li	a4,23
    8000303c:	00f76f63          	bltu	a4,a5,8000305a <syscall+0x44>
    80003040:	00369713          	sll	a4,a3,0x3
    80003044:	00005797          	auipc	a5,0x5
    80003048:	43478793          	add	a5,a5,1076 # 80008478 <syscalls>
    8000304c:	97ba                	add	a5,a5,a4
    8000304e:	639c                	ld	a5,0(a5)
    80003050:	c789                	beqz	a5,8000305a <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80003052:	9782                	jalr	a5
    80003054:	06a93823          	sd	a0,112(s2)
    80003058:	a839                	j	80003076 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000305a:	15848613          	add	a2,s1,344
    8000305e:	588c                	lw	a1,48(s1)
    80003060:	00005517          	auipc	a0,0x5
    80003064:	3e050513          	add	a0,a0,992 # 80008440 <states.0+0x150>
    80003068:	ffffd097          	auipc	ra,0xffffd
    8000306c:	51e080e7          	jalr	1310(ra) # 80000586 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003070:	6cbc                	ld	a5,88(s1)
    80003072:	577d                	li	a4,-1
    80003074:	fbb8                	sd	a4,112(a5)
  }
}
    80003076:	60e2                	ld	ra,24(sp)
    80003078:	6442                	ld	s0,16(sp)
    8000307a:	64a2                	ld	s1,8(sp)
    8000307c:	6902                	ld	s2,0(sp)
    8000307e:	6105                	add	sp,sp,32
    80003080:	8082                	ret

0000000080003082 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003082:	1101                	add	sp,sp,-32
    80003084:	ec06                	sd	ra,24(sp)
    80003086:	e822                	sd	s0,16(sp)
    80003088:	1000                	add	s0,sp,32
  int n;
  argint(0, &n);
    8000308a:	fec40593          	add	a1,s0,-20
    8000308e:	4501                	li	a0,0
    80003090:	00000097          	auipc	ra,0x0
    80003094:	f0e080e7          	jalr	-242(ra) # 80002f9e <argint>
  exit(n);
    80003098:	fec42503          	lw	a0,-20(s0)
    8000309c:	fffff097          	auipc	ra,0xfffff
    800030a0:	38e080e7          	jalr	910(ra) # 8000242a <exit>
  return 0; // not reached
}
    800030a4:	4501                	li	a0,0
    800030a6:	60e2                	ld	ra,24(sp)
    800030a8:	6442                	ld	s0,16(sp)
    800030aa:	6105                	add	sp,sp,32
    800030ac:	8082                	ret

00000000800030ae <sys_getpid>:

uint64
sys_getpid(void)
{
    800030ae:	1141                	add	sp,sp,-16
    800030b0:	e406                	sd	ra,8(sp)
    800030b2:	e022                	sd	s0,0(sp)
    800030b4:	0800                	add	s0,sp,16
  return myproc()->pid;
    800030b6:	fffff097          	auipc	ra,0xfffff
    800030ba:	98c080e7          	jalr	-1652(ra) # 80001a42 <myproc>
}
    800030be:	5908                	lw	a0,48(a0)
    800030c0:	60a2                	ld	ra,8(sp)
    800030c2:	6402                	ld	s0,0(sp)
    800030c4:	0141                	add	sp,sp,16
    800030c6:	8082                	ret

00000000800030c8 <sys_fork>:

uint64
sys_fork(void)
{
    800030c8:	1141                	add	sp,sp,-16
    800030ca:	e406                	sd	ra,8(sp)
    800030cc:	e022                	sd	s0,0(sp)
    800030ce:	0800                	add	s0,sp,16
  return fork();
    800030d0:	fffff097          	auipc	ra,0xfffff
    800030d4:	d50080e7          	jalr	-688(ra) # 80001e20 <fork>
}
    800030d8:	60a2                	ld	ra,8(sp)
    800030da:	6402                	ld	s0,0(sp)
    800030dc:	0141                	add	sp,sp,16
    800030de:	8082                	ret

00000000800030e0 <sys_wait>:

uint64
sys_wait(void)
{
    800030e0:	1101                	add	sp,sp,-32
    800030e2:	ec06                	sd	ra,24(sp)
    800030e4:	e822                	sd	s0,16(sp)
    800030e6:	1000                	add	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    800030e8:	fe840593          	add	a1,s0,-24
    800030ec:	4501                	li	a0,0
    800030ee:	00000097          	auipc	ra,0x0
    800030f2:	ed0080e7          	jalr	-304(ra) # 80002fbe <argaddr>
  return wait(p);
    800030f6:	fe843503          	ld	a0,-24(s0)
    800030fa:	fffff097          	auipc	ra,0xfffff
    800030fe:	4e2080e7          	jalr	1250(ra) # 800025dc <wait>
}
    80003102:	60e2                	ld	ra,24(sp)
    80003104:	6442                	ld	s0,16(sp)
    80003106:	6105                	add	sp,sp,32
    80003108:	8082                	ret

000000008000310a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000310a:	7179                	add	sp,sp,-48
    8000310c:	f406                	sd	ra,40(sp)
    8000310e:	f022                	sd	s0,32(sp)
    80003110:	ec26                	sd	s1,24(sp)
    80003112:	1800                	add	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80003114:	fdc40593          	add	a1,s0,-36
    80003118:	4501                	li	a0,0
    8000311a:	00000097          	auipc	ra,0x0
    8000311e:	e84080e7          	jalr	-380(ra) # 80002f9e <argint>
  addr = myproc()->sz;
    80003122:	fffff097          	auipc	ra,0xfffff
    80003126:	920080e7          	jalr	-1760(ra) # 80001a42 <myproc>
    8000312a:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    8000312c:	fdc42503          	lw	a0,-36(s0)
    80003130:	fffff097          	auipc	ra,0xfffff
    80003134:	c94080e7          	jalr	-876(ra) # 80001dc4 <growproc>
    80003138:	00054863          	bltz	a0,80003148 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    8000313c:	8526                	mv	a0,s1
    8000313e:	70a2                	ld	ra,40(sp)
    80003140:	7402                	ld	s0,32(sp)
    80003142:	64e2                	ld	s1,24(sp)
    80003144:	6145                	add	sp,sp,48
    80003146:	8082                	ret
    return -1;
    80003148:	54fd                	li	s1,-1
    8000314a:	bfcd                	j	8000313c <sys_sbrk+0x32>

000000008000314c <sys_sleep>:

uint64
sys_sleep(void)
{
    8000314c:	7139                	add	sp,sp,-64
    8000314e:	fc06                	sd	ra,56(sp)
    80003150:	f822                	sd	s0,48(sp)
    80003152:	f426                	sd	s1,40(sp)
    80003154:	f04a                	sd	s2,32(sp)
    80003156:	ec4e                	sd	s3,24(sp)
    80003158:	0080                	add	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    8000315a:	fcc40593          	add	a1,s0,-52
    8000315e:	4501                	li	a0,0
    80003160:	00000097          	auipc	ra,0x0
    80003164:	e3e080e7          	jalr	-450(ra) # 80002f9e <argint>
  acquire(&tickslock);
    80003168:	00234517          	auipc	a0,0x234
    8000316c:	03850513          	add	a0,a0,56 # 802371a0 <tickslock>
    80003170:	ffffe097          	auipc	ra,0xffffe
    80003174:	b2c080e7          	jalr	-1236(ra) # 80000c9c <acquire>
  ticks0 = ticks;
    80003178:	00005917          	auipc	s2,0x5
    8000317c:	78892903          	lw	s2,1928(s2) # 80008900 <ticks>
  while (ticks - ticks0 < n)
    80003180:	fcc42783          	lw	a5,-52(s0)
    80003184:	cf9d                	beqz	a5,800031c2 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003186:	00234997          	auipc	s3,0x234
    8000318a:	01a98993          	add	s3,s3,26 # 802371a0 <tickslock>
    8000318e:	00005497          	auipc	s1,0x5
    80003192:	77248493          	add	s1,s1,1906 # 80008900 <ticks>
    if (killed(myproc()))
    80003196:	fffff097          	auipc	ra,0xfffff
    8000319a:	8ac080e7          	jalr	-1876(ra) # 80001a42 <myproc>
    8000319e:	fffff097          	auipc	ra,0xfffff
    800031a2:	40c080e7          	jalr	1036(ra) # 800025aa <killed>
    800031a6:	ed15                	bnez	a0,800031e2 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    800031a8:	85ce                	mv	a1,s3
    800031aa:	8526                	mv	a0,s1
    800031ac:	fffff097          	auipc	ra,0xfffff
    800031b0:	14a080e7          	jalr	330(ra) # 800022f6 <sleep>
  while (ticks - ticks0 < n)
    800031b4:	409c                	lw	a5,0(s1)
    800031b6:	412787bb          	subw	a5,a5,s2
    800031ba:	fcc42703          	lw	a4,-52(s0)
    800031be:	fce7ece3          	bltu	a5,a4,80003196 <sys_sleep+0x4a>
  }
  release(&tickslock);
    800031c2:	00234517          	auipc	a0,0x234
    800031c6:	fde50513          	add	a0,a0,-34 # 802371a0 <tickslock>
    800031ca:	ffffe097          	auipc	ra,0xffffe
    800031ce:	b86080e7          	jalr	-1146(ra) # 80000d50 <release>
  return 0;
    800031d2:	4501                	li	a0,0
}
    800031d4:	70e2                	ld	ra,56(sp)
    800031d6:	7442                	ld	s0,48(sp)
    800031d8:	74a2                	ld	s1,40(sp)
    800031da:	7902                	ld	s2,32(sp)
    800031dc:	69e2                	ld	s3,24(sp)
    800031de:	6121                	add	sp,sp,64
    800031e0:	8082                	ret
      release(&tickslock);
    800031e2:	00234517          	auipc	a0,0x234
    800031e6:	fbe50513          	add	a0,a0,-66 # 802371a0 <tickslock>
    800031ea:	ffffe097          	auipc	ra,0xffffe
    800031ee:	b66080e7          	jalr	-1178(ra) # 80000d50 <release>
      return -1;
    800031f2:	557d                	li	a0,-1
    800031f4:	b7c5                	j	800031d4 <sys_sleep+0x88>

00000000800031f6 <sys_kill>:

uint64
sys_kill(void)
{
    800031f6:	1101                	add	sp,sp,-32
    800031f8:	ec06                	sd	ra,24(sp)
    800031fa:	e822                	sd	s0,16(sp)
    800031fc:	1000                	add	s0,sp,32
  int pid;

  argint(0, &pid);
    800031fe:	fec40593          	add	a1,s0,-20
    80003202:	4501                	li	a0,0
    80003204:	00000097          	auipc	ra,0x0
    80003208:	d9a080e7          	jalr	-614(ra) # 80002f9e <argint>
  return kill(pid);
    8000320c:	fec42503          	lw	a0,-20(s0)
    80003210:	fffff097          	auipc	ra,0xfffff
    80003214:	2fc080e7          	jalr	764(ra) # 8000250c <kill>
}
    80003218:	60e2                	ld	ra,24(sp)
    8000321a:	6442                	ld	s0,16(sp)
    8000321c:	6105                	add	sp,sp,32
    8000321e:	8082                	ret

0000000080003220 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003220:	1101                	add	sp,sp,-32
    80003222:	ec06                	sd	ra,24(sp)
    80003224:	e822                	sd	s0,16(sp)
    80003226:	e426                	sd	s1,8(sp)
    80003228:	1000                	add	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000322a:	00234517          	auipc	a0,0x234
    8000322e:	f7650513          	add	a0,a0,-138 # 802371a0 <tickslock>
    80003232:	ffffe097          	auipc	ra,0xffffe
    80003236:	a6a080e7          	jalr	-1430(ra) # 80000c9c <acquire>
  xticks = ticks;
    8000323a:	00005497          	auipc	s1,0x5
    8000323e:	6c64a483          	lw	s1,1734(s1) # 80008900 <ticks>
  release(&tickslock);
    80003242:	00234517          	auipc	a0,0x234
    80003246:	f5e50513          	add	a0,a0,-162 # 802371a0 <tickslock>
    8000324a:	ffffe097          	auipc	ra,0xffffe
    8000324e:	b06080e7          	jalr	-1274(ra) # 80000d50 <release>
  return xticks;
}
    80003252:	02049513          	sll	a0,s1,0x20
    80003256:	9101                	srl	a0,a0,0x20
    80003258:	60e2                	ld	ra,24(sp)
    8000325a:	6442                	ld	s0,16(sp)
    8000325c:	64a2                	ld	s1,8(sp)
    8000325e:	6105                	add	sp,sp,32
    80003260:	8082                	ret

0000000080003262 <sys_waitx>:

uint64
sys_waitx(void)
{
    80003262:	7139                	add	sp,sp,-64
    80003264:	fc06                	sd	ra,56(sp)
    80003266:	f822                	sd	s0,48(sp)
    80003268:	f426                	sd	s1,40(sp)
    8000326a:	f04a                	sd	s2,32(sp)
    8000326c:	0080                	add	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    8000326e:	fd840593          	add	a1,s0,-40
    80003272:	4501                	li	a0,0
    80003274:	00000097          	auipc	ra,0x0
    80003278:	d4a080e7          	jalr	-694(ra) # 80002fbe <argaddr>
  argaddr(1, &addr1); // user virtual memory
    8000327c:	fd040593          	add	a1,s0,-48
    80003280:	4505                	li	a0,1
    80003282:	00000097          	auipc	ra,0x0
    80003286:	d3c080e7          	jalr	-708(ra) # 80002fbe <argaddr>
  argaddr(2, &addr2);
    8000328a:	fc840593          	add	a1,s0,-56
    8000328e:	4509                	li	a0,2
    80003290:	00000097          	auipc	ra,0x0
    80003294:	d2e080e7          	jalr	-722(ra) # 80002fbe <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80003298:	fc040613          	add	a2,s0,-64
    8000329c:	fc440593          	add	a1,s0,-60
    800032a0:	fd843503          	ld	a0,-40(s0)
    800032a4:	fffff097          	auipc	ra,0xfffff
    800032a8:	5c2080e7          	jalr	1474(ra) # 80002866 <waitx>
    800032ac:	892a                	mv	s2,a0
  struct proc *p = myproc();
    800032ae:	ffffe097          	auipc	ra,0xffffe
    800032b2:	794080e7          	jalr	1940(ra) # 80001a42 <myproc>
    800032b6:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800032b8:	4691                	li	a3,4
    800032ba:	fc440613          	add	a2,s0,-60
    800032be:	fd043583          	ld	a1,-48(s0)
    800032c2:	6928                	ld	a0,80(a0)
    800032c4:	ffffe097          	auipc	ra,0xffffe
    800032c8:	43e080e7          	jalr	1086(ra) # 80001702 <copyout>
    return -1;
    800032cc:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800032ce:	00054f63          	bltz	a0,800032ec <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    800032d2:	4691                	li	a3,4
    800032d4:	fc040613          	add	a2,s0,-64
    800032d8:	fc843583          	ld	a1,-56(s0)
    800032dc:	68a8                	ld	a0,80(s1)
    800032de:	ffffe097          	auipc	ra,0xffffe
    800032e2:	424080e7          	jalr	1060(ra) # 80001702 <copyout>
    800032e6:	00054a63          	bltz	a0,800032fa <sys_waitx+0x98>
    return -1;
  return ret;
    800032ea:	87ca                	mv	a5,s2
}
    800032ec:	853e                	mv	a0,a5
    800032ee:	70e2                	ld	ra,56(sp)
    800032f0:	7442                	ld	s0,48(sp)
    800032f2:	74a2                	ld	s1,40(sp)
    800032f4:	7902                	ld	s2,32(sp)
    800032f6:	6121                	add	sp,sp,64
    800032f8:	8082                	ret
    return -1;
    800032fa:	57fd                	li	a5,-1
    800032fc:	bfc5                	j	800032ec <sys_waitx+0x8a>

00000000800032fe <sys_setpriority>:

uint64
sys_setpriority(void)
{
    800032fe:	1141                	add	sp,sp,-16
    80003300:	e422                	sd	s0,8(sp)
    80003302:	0800                	add	s0,sp,16
    }
    return old_priority;
  #else
    return 0;
  #endif
}
    80003304:	4501                	li	a0,0
    80003306:	6422                	ld	s0,8(sp)
    80003308:	0141                	add	sp,sp,16
    8000330a:	8082                	ret

000000008000330c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000330c:	7179                	add	sp,sp,-48
    8000330e:	f406                	sd	ra,40(sp)
    80003310:	f022                	sd	s0,32(sp)
    80003312:	ec26                	sd	s1,24(sp)
    80003314:	e84a                	sd	s2,16(sp)
    80003316:	e44e                	sd	s3,8(sp)
    80003318:	e052                	sd	s4,0(sp)
    8000331a:	1800                	add	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000331c:	00005597          	auipc	a1,0x5
    80003320:	22458593          	add	a1,a1,548 # 80008540 <syscalls+0xc8>
    80003324:	00234517          	auipc	a0,0x234
    80003328:	e9450513          	add	a0,a0,-364 # 802371b8 <bcache>
    8000332c:	ffffe097          	auipc	ra,0xffffe
    80003330:	8e0080e7          	jalr	-1824(ra) # 80000c0c <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003334:	0023c797          	auipc	a5,0x23c
    80003338:	e8478793          	add	a5,a5,-380 # 8023f1b8 <bcache+0x8000>
    8000333c:	0023c717          	auipc	a4,0x23c
    80003340:	0e470713          	add	a4,a4,228 # 8023f420 <bcache+0x8268>
    80003344:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003348:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000334c:	00234497          	auipc	s1,0x234
    80003350:	e8448493          	add	s1,s1,-380 # 802371d0 <bcache+0x18>
    b->next = bcache.head.next;
    80003354:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003356:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003358:	00005a17          	auipc	s4,0x5
    8000335c:	1f0a0a13          	add	s4,s4,496 # 80008548 <syscalls+0xd0>
    b->next = bcache.head.next;
    80003360:	2b893783          	ld	a5,696(s2)
    80003364:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003366:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000336a:	85d2                	mv	a1,s4
    8000336c:	01048513          	add	a0,s1,16
    80003370:	00001097          	auipc	ra,0x1
    80003374:	496080e7          	jalr	1174(ra) # 80004806 <initsleeplock>
    bcache.head.next->prev = b;
    80003378:	2b893783          	ld	a5,696(s2)
    8000337c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000337e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003382:	45848493          	add	s1,s1,1112
    80003386:	fd349de3          	bne	s1,s3,80003360 <binit+0x54>
  }
}
    8000338a:	70a2                	ld	ra,40(sp)
    8000338c:	7402                	ld	s0,32(sp)
    8000338e:	64e2                	ld	s1,24(sp)
    80003390:	6942                	ld	s2,16(sp)
    80003392:	69a2                	ld	s3,8(sp)
    80003394:	6a02                	ld	s4,0(sp)
    80003396:	6145                	add	sp,sp,48
    80003398:	8082                	ret

000000008000339a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000339a:	7179                	add	sp,sp,-48
    8000339c:	f406                	sd	ra,40(sp)
    8000339e:	f022                	sd	s0,32(sp)
    800033a0:	ec26                	sd	s1,24(sp)
    800033a2:	e84a                	sd	s2,16(sp)
    800033a4:	e44e                	sd	s3,8(sp)
    800033a6:	1800                	add	s0,sp,48
    800033a8:	892a                	mv	s2,a0
    800033aa:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800033ac:	00234517          	auipc	a0,0x234
    800033b0:	e0c50513          	add	a0,a0,-500 # 802371b8 <bcache>
    800033b4:	ffffe097          	auipc	ra,0xffffe
    800033b8:	8e8080e7          	jalr	-1816(ra) # 80000c9c <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800033bc:	0023c497          	auipc	s1,0x23c
    800033c0:	0b44b483          	ld	s1,180(s1) # 8023f470 <bcache+0x82b8>
    800033c4:	0023c797          	auipc	a5,0x23c
    800033c8:	05c78793          	add	a5,a5,92 # 8023f420 <bcache+0x8268>
    800033cc:	02f48f63          	beq	s1,a5,8000340a <bread+0x70>
    800033d0:	873e                	mv	a4,a5
    800033d2:	a021                	j	800033da <bread+0x40>
    800033d4:	68a4                	ld	s1,80(s1)
    800033d6:	02e48a63          	beq	s1,a4,8000340a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800033da:	449c                	lw	a5,8(s1)
    800033dc:	ff279ce3          	bne	a5,s2,800033d4 <bread+0x3a>
    800033e0:	44dc                	lw	a5,12(s1)
    800033e2:	ff3799e3          	bne	a5,s3,800033d4 <bread+0x3a>
      b->refcnt++;
    800033e6:	40bc                	lw	a5,64(s1)
    800033e8:	2785                	addw	a5,a5,1
    800033ea:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800033ec:	00234517          	auipc	a0,0x234
    800033f0:	dcc50513          	add	a0,a0,-564 # 802371b8 <bcache>
    800033f4:	ffffe097          	auipc	ra,0xffffe
    800033f8:	95c080e7          	jalr	-1700(ra) # 80000d50 <release>
      acquiresleep(&b->lock);
    800033fc:	01048513          	add	a0,s1,16
    80003400:	00001097          	auipc	ra,0x1
    80003404:	440080e7          	jalr	1088(ra) # 80004840 <acquiresleep>
      return b;
    80003408:	a8b9                	j	80003466 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000340a:	0023c497          	auipc	s1,0x23c
    8000340e:	05e4b483          	ld	s1,94(s1) # 8023f468 <bcache+0x82b0>
    80003412:	0023c797          	auipc	a5,0x23c
    80003416:	00e78793          	add	a5,a5,14 # 8023f420 <bcache+0x8268>
    8000341a:	00f48863          	beq	s1,a5,8000342a <bread+0x90>
    8000341e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003420:	40bc                	lw	a5,64(s1)
    80003422:	cf81                	beqz	a5,8000343a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003424:	64a4                	ld	s1,72(s1)
    80003426:	fee49de3          	bne	s1,a4,80003420 <bread+0x86>
  panic("bget: no buffers");
    8000342a:	00005517          	auipc	a0,0x5
    8000342e:	12650513          	add	a0,a0,294 # 80008550 <syscalls+0xd8>
    80003432:	ffffd097          	auipc	ra,0xffffd
    80003436:	10a080e7          	jalr	266(ra) # 8000053c <panic>
      b->dev = dev;
    8000343a:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000343e:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003442:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003446:	4785                	li	a5,1
    80003448:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000344a:	00234517          	auipc	a0,0x234
    8000344e:	d6e50513          	add	a0,a0,-658 # 802371b8 <bcache>
    80003452:	ffffe097          	auipc	ra,0xffffe
    80003456:	8fe080e7          	jalr	-1794(ra) # 80000d50 <release>
      acquiresleep(&b->lock);
    8000345a:	01048513          	add	a0,s1,16
    8000345e:	00001097          	auipc	ra,0x1
    80003462:	3e2080e7          	jalr	994(ra) # 80004840 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003466:	409c                	lw	a5,0(s1)
    80003468:	cb89                	beqz	a5,8000347a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000346a:	8526                	mv	a0,s1
    8000346c:	70a2                	ld	ra,40(sp)
    8000346e:	7402                	ld	s0,32(sp)
    80003470:	64e2                	ld	s1,24(sp)
    80003472:	6942                	ld	s2,16(sp)
    80003474:	69a2                	ld	s3,8(sp)
    80003476:	6145                	add	sp,sp,48
    80003478:	8082                	ret
    virtio_disk_rw(b, 0);
    8000347a:	4581                	li	a1,0
    8000347c:	8526                	mv	a0,s1
    8000347e:	00003097          	auipc	ra,0x3
    80003482:	fa4080e7          	jalr	-92(ra) # 80006422 <virtio_disk_rw>
    b->valid = 1;
    80003486:	4785                	li	a5,1
    80003488:	c09c                	sw	a5,0(s1)
  return b;
    8000348a:	b7c5                	j	8000346a <bread+0xd0>

000000008000348c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000348c:	1101                	add	sp,sp,-32
    8000348e:	ec06                	sd	ra,24(sp)
    80003490:	e822                	sd	s0,16(sp)
    80003492:	e426                	sd	s1,8(sp)
    80003494:	1000                	add	s0,sp,32
    80003496:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003498:	0541                	add	a0,a0,16
    8000349a:	00001097          	auipc	ra,0x1
    8000349e:	440080e7          	jalr	1088(ra) # 800048da <holdingsleep>
    800034a2:	cd01                	beqz	a0,800034ba <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800034a4:	4585                	li	a1,1
    800034a6:	8526                	mv	a0,s1
    800034a8:	00003097          	auipc	ra,0x3
    800034ac:	f7a080e7          	jalr	-134(ra) # 80006422 <virtio_disk_rw>
}
    800034b0:	60e2                	ld	ra,24(sp)
    800034b2:	6442                	ld	s0,16(sp)
    800034b4:	64a2                	ld	s1,8(sp)
    800034b6:	6105                	add	sp,sp,32
    800034b8:	8082                	ret
    panic("bwrite");
    800034ba:	00005517          	auipc	a0,0x5
    800034be:	0ae50513          	add	a0,a0,174 # 80008568 <syscalls+0xf0>
    800034c2:	ffffd097          	auipc	ra,0xffffd
    800034c6:	07a080e7          	jalr	122(ra) # 8000053c <panic>

00000000800034ca <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800034ca:	1101                	add	sp,sp,-32
    800034cc:	ec06                	sd	ra,24(sp)
    800034ce:	e822                	sd	s0,16(sp)
    800034d0:	e426                	sd	s1,8(sp)
    800034d2:	e04a                	sd	s2,0(sp)
    800034d4:	1000                	add	s0,sp,32
    800034d6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800034d8:	01050913          	add	s2,a0,16
    800034dc:	854a                	mv	a0,s2
    800034de:	00001097          	auipc	ra,0x1
    800034e2:	3fc080e7          	jalr	1020(ra) # 800048da <holdingsleep>
    800034e6:	c925                	beqz	a0,80003556 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    800034e8:	854a                	mv	a0,s2
    800034ea:	00001097          	auipc	ra,0x1
    800034ee:	3ac080e7          	jalr	940(ra) # 80004896 <releasesleep>

  acquire(&bcache.lock);
    800034f2:	00234517          	auipc	a0,0x234
    800034f6:	cc650513          	add	a0,a0,-826 # 802371b8 <bcache>
    800034fa:	ffffd097          	auipc	ra,0xffffd
    800034fe:	7a2080e7          	jalr	1954(ra) # 80000c9c <acquire>
  b->refcnt--;
    80003502:	40bc                	lw	a5,64(s1)
    80003504:	37fd                	addw	a5,a5,-1
    80003506:	0007871b          	sext.w	a4,a5
    8000350a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000350c:	e71d                	bnez	a4,8000353a <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000350e:	68b8                	ld	a4,80(s1)
    80003510:	64bc                	ld	a5,72(s1)
    80003512:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80003514:	68b8                	ld	a4,80(s1)
    80003516:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003518:	0023c797          	auipc	a5,0x23c
    8000351c:	ca078793          	add	a5,a5,-864 # 8023f1b8 <bcache+0x8000>
    80003520:	2b87b703          	ld	a4,696(a5)
    80003524:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003526:	0023c717          	auipc	a4,0x23c
    8000352a:	efa70713          	add	a4,a4,-262 # 8023f420 <bcache+0x8268>
    8000352e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003530:	2b87b703          	ld	a4,696(a5)
    80003534:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003536:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000353a:	00234517          	auipc	a0,0x234
    8000353e:	c7e50513          	add	a0,a0,-898 # 802371b8 <bcache>
    80003542:	ffffe097          	auipc	ra,0xffffe
    80003546:	80e080e7          	jalr	-2034(ra) # 80000d50 <release>
}
    8000354a:	60e2                	ld	ra,24(sp)
    8000354c:	6442                	ld	s0,16(sp)
    8000354e:	64a2                	ld	s1,8(sp)
    80003550:	6902                	ld	s2,0(sp)
    80003552:	6105                	add	sp,sp,32
    80003554:	8082                	ret
    panic("brelse");
    80003556:	00005517          	auipc	a0,0x5
    8000355a:	01a50513          	add	a0,a0,26 # 80008570 <syscalls+0xf8>
    8000355e:	ffffd097          	auipc	ra,0xffffd
    80003562:	fde080e7          	jalr	-34(ra) # 8000053c <panic>

0000000080003566 <bpin>:

void
bpin(struct buf *b) {
    80003566:	1101                	add	sp,sp,-32
    80003568:	ec06                	sd	ra,24(sp)
    8000356a:	e822                	sd	s0,16(sp)
    8000356c:	e426                	sd	s1,8(sp)
    8000356e:	1000                	add	s0,sp,32
    80003570:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003572:	00234517          	auipc	a0,0x234
    80003576:	c4650513          	add	a0,a0,-954 # 802371b8 <bcache>
    8000357a:	ffffd097          	auipc	ra,0xffffd
    8000357e:	722080e7          	jalr	1826(ra) # 80000c9c <acquire>
  b->refcnt++;
    80003582:	40bc                	lw	a5,64(s1)
    80003584:	2785                	addw	a5,a5,1
    80003586:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003588:	00234517          	auipc	a0,0x234
    8000358c:	c3050513          	add	a0,a0,-976 # 802371b8 <bcache>
    80003590:	ffffd097          	auipc	ra,0xffffd
    80003594:	7c0080e7          	jalr	1984(ra) # 80000d50 <release>
}
    80003598:	60e2                	ld	ra,24(sp)
    8000359a:	6442                	ld	s0,16(sp)
    8000359c:	64a2                	ld	s1,8(sp)
    8000359e:	6105                	add	sp,sp,32
    800035a0:	8082                	ret

00000000800035a2 <bunpin>:

void
bunpin(struct buf *b) {
    800035a2:	1101                	add	sp,sp,-32
    800035a4:	ec06                	sd	ra,24(sp)
    800035a6:	e822                	sd	s0,16(sp)
    800035a8:	e426                	sd	s1,8(sp)
    800035aa:	1000                	add	s0,sp,32
    800035ac:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800035ae:	00234517          	auipc	a0,0x234
    800035b2:	c0a50513          	add	a0,a0,-1014 # 802371b8 <bcache>
    800035b6:	ffffd097          	auipc	ra,0xffffd
    800035ba:	6e6080e7          	jalr	1766(ra) # 80000c9c <acquire>
  b->refcnt--;
    800035be:	40bc                	lw	a5,64(s1)
    800035c0:	37fd                	addw	a5,a5,-1
    800035c2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035c4:	00234517          	auipc	a0,0x234
    800035c8:	bf450513          	add	a0,a0,-1036 # 802371b8 <bcache>
    800035cc:	ffffd097          	auipc	ra,0xffffd
    800035d0:	784080e7          	jalr	1924(ra) # 80000d50 <release>
}
    800035d4:	60e2                	ld	ra,24(sp)
    800035d6:	6442                	ld	s0,16(sp)
    800035d8:	64a2                	ld	s1,8(sp)
    800035da:	6105                	add	sp,sp,32
    800035dc:	8082                	ret

00000000800035de <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800035de:	1101                	add	sp,sp,-32
    800035e0:	ec06                	sd	ra,24(sp)
    800035e2:	e822                	sd	s0,16(sp)
    800035e4:	e426                	sd	s1,8(sp)
    800035e6:	e04a                	sd	s2,0(sp)
    800035e8:	1000                	add	s0,sp,32
    800035ea:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800035ec:	00d5d59b          	srlw	a1,a1,0xd
    800035f0:	0023c797          	auipc	a5,0x23c
    800035f4:	2a47a783          	lw	a5,676(a5) # 8023f894 <sb+0x1c>
    800035f8:	9dbd                	addw	a1,a1,a5
    800035fa:	00000097          	auipc	ra,0x0
    800035fe:	da0080e7          	jalr	-608(ra) # 8000339a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003602:	0074f713          	and	a4,s1,7
    80003606:	4785                	li	a5,1
    80003608:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000360c:	14ce                	sll	s1,s1,0x33
    8000360e:	90d9                	srl	s1,s1,0x36
    80003610:	00950733          	add	a4,a0,s1
    80003614:	05874703          	lbu	a4,88(a4)
    80003618:	00e7f6b3          	and	a3,a5,a4
    8000361c:	c69d                	beqz	a3,8000364a <bfree+0x6c>
    8000361e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003620:	94aa                	add	s1,s1,a0
    80003622:	fff7c793          	not	a5,a5
    80003626:	8f7d                	and	a4,a4,a5
    80003628:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000362c:	00001097          	auipc	ra,0x1
    80003630:	0f6080e7          	jalr	246(ra) # 80004722 <log_write>
  brelse(bp);
    80003634:	854a                	mv	a0,s2
    80003636:	00000097          	auipc	ra,0x0
    8000363a:	e94080e7          	jalr	-364(ra) # 800034ca <brelse>
}
    8000363e:	60e2                	ld	ra,24(sp)
    80003640:	6442                	ld	s0,16(sp)
    80003642:	64a2                	ld	s1,8(sp)
    80003644:	6902                	ld	s2,0(sp)
    80003646:	6105                	add	sp,sp,32
    80003648:	8082                	ret
    panic("freeing free block");
    8000364a:	00005517          	auipc	a0,0x5
    8000364e:	f2e50513          	add	a0,a0,-210 # 80008578 <syscalls+0x100>
    80003652:	ffffd097          	auipc	ra,0xffffd
    80003656:	eea080e7          	jalr	-278(ra) # 8000053c <panic>

000000008000365a <balloc>:
{
    8000365a:	711d                	add	sp,sp,-96
    8000365c:	ec86                	sd	ra,88(sp)
    8000365e:	e8a2                	sd	s0,80(sp)
    80003660:	e4a6                	sd	s1,72(sp)
    80003662:	e0ca                	sd	s2,64(sp)
    80003664:	fc4e                	sd	s3,56(sp)
    80003666:	f852                	sd	s4,48(sp)
    80003668:	f456                	sd	s5,40(sp)
    8000366a:	f05a                	sd	s6,32(sp)
    8000366c:	ec5e                	sd	s7,24(sp)
    8000366e:	e862                	sd	s8,16(sp)
    80003670:	e466                	sd	s9,8(sp)
    80003672:	1080                	add	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003674:	0023c797          	auipc	a5,0x23c
    80003678:	2087a783          	lw	a5,520(a5) # 8023f87c <sb+0x4>
    8000367c:	cff5                	beqz	a5,80003778 <balloc+0x11e>
    8000367e:	8baa                	mv	s7,a0
    80003680:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003682:	0023cb17          	auipc	s6,0x23c
    80003686:	1f6b0b13          	add	s6,s6,502 # 8023f878 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000368a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000368c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000368e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003690:	6c89                	lui	s9,0x2
    80003692:	a061                	j	8000371a <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003694:	97ca                	add	a5,a5,s2
    80003696:	8e55                	or	a2,a2,a3
    80003698:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    8000369c:	854a                	mv	a0,s2
    8000369e:	00001097          	auipc	ra,0x1
    800036a2:	084080e7          	jalr	132(ra) # 80004722 <log_write>
        brelse(bp);
    800036a6:	854a                	mv	a0,s2
    800036a8:	00000097          	auipc	ra,0x0
    800036ac:	e22080e7          	jalr	-478(ra) # 800034ca <brelse>
  bp = bread(dev, bno);
    800036b0:	85a6                	mv	a1,s1
    800036b2:	855e                	mv	a0,s7
    800036b4:	00000097          	auipc	ra,0x0
    800036b8:	ce6080e7          	jalr	-794(ra) # 8000339a <bread>
    800036bc:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800036be:	40000613          	li	a2,1024
    800036c2:	4581                	li	a1,0
    800036c4:	05850513          	add	a0,a0,88
    800036c8:	ffffd097          	auipc	ra,0xffffd
    800036cc:	6d0080e7          	jalr	1744(ra) # 80000d98 <memset>
  log_write(bp);
    800036d0:	854a                	mv	a0,s2
    800036d2:	00001097          	auipc	ra,0x1
    800036d6:	050080e7          	jalr	80(ra) # 80004722 <log_write>
  brelse(bp);
    800036da:	854a                	mv	a0,s2
    800036dc:	00000097          	auipc	ra,0x0
    800036e0:	dee080e7          	jalr	-530(ra) # 800034ca <brelse>
}
    800036e4:	8526                	mv	a0,s1
    800036e6:	60e6                	ld	ra,88(sp)
    800036e8:	6446                	ld	s0,80(sp)
    800036ea:	64a6                	ld	s1,72(sp)
    800036ec:	6906                	ld	s2,64(sp)
    800036ee:	79e2                	ld	s3,56(sp)
    800036f0:	7a42                	ld	s4,48(sp)
    800036f2:	7aa2                	ld	s5,40(sp)
    800036f4:	7b02                	ld	s6,32(sp)
    800036f6:	6be2                	ld	s7,24(sp)
    800036f8:	6c42                	ld	s8,16(sp)
    800036fa:	6ca2                	ld	s9,8(sp)
    800036fc:	6125                	add	sp,sp,96
    800036fe:	8082                	ret
    brelse(bp);
    80003700:	854a                	mv	a0,s2
    80003702:	00000097          	auipc	ra,0x0
    80003706:	dc8080e7          	jalr	-568(ra) # 800034ca <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000370a:	015c87bb          	addw	a5,s9,s5
    8000370e:	00078a9b          	sext.w	s5,a5
    80003712:	004b2703          	lw	a4,4(s6)
    80003716:	06eaf163          	bgeu	s5,a4,80003778 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    8000371a:	41fad79b          	sraw	a5,s5,0x1f
    8000371e:	0137d79b          	srlw	a5,a5,0x13
    80003722:	015787bb          	addw	a5,a5,s5
    80003726:	40d7d79b          	sraw	a5,a5,0xd
    8000372a:	01cb2583          	lw	a1,28(s6)
    8000372e:	9dbd                	addw	a1,a1,a5
    80003730:	855e                	mv	a0,s7
    80003732:	00000097          	auipc	ra,0x0
    80003736:	c68080e7          	jalr	-920(ra) # 8000339a <bread>
    8000373a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000373c:	004b2503          	lw	a0,4(s6)
    80003740:	000a849b          	sext.w	s1,s5
    80003744:	8762                	mv	a4,s8
    80003746:	faa4fde3          	bgeu	s1,a0,80003700 <balloc+0xa6>
      m = 1 << (bi % 8);
    8000374a:	00777693          	and	a3,a4,7
    8000374e:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003752:	41f7579b          	sraw	a5,a4,0x1f
    80003756:	01d7d79b          	srlw	a5,a5,0x1d
    8000375a:	9fb9                	addw	a5,a5,a4
    8000375c:	4037d79b          	sraw	a5,a5,0x3
    80003760:	00f90633          	add	a2,s2,a5
    80003764:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    80003768:	00c6f5b3          	and	a1,a3,a2
    8000376c:	d585                	beqz	a1,80003694 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000376e:	2705                	addw	a4,a4,1
    80003770:	2485                	addw	s1,s1,1
    80003772:	fd471ae3          	bne	a4,s4,80003746 <balloc+0xec>
    80003776:	b769                	j	80003700 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003778:	00005517          	auipc	a0,0x5
    8000377c:	e1850513          	add	a0,a0,-488 # 80008590 <syscalls+0x118>
    80003780:	ffffd097          	auipc	ra,0xffffd
    80003784:	e06080e7          	jalr	-506(ra) # 80000586 <printf>
  return 0;
    80003788:	4481                	li	s1,0
    8000378a:	bfa9                	j	800036e4 <balloc+0x8a>

000000008000378c <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000378c:	7179                	add	sp,sp,-48
    8000378e:	f406                	sd	ra,40(sp)
    80003790:	f022                	sd	s0,32(sp)
    80003792:	ec26                	sd	s1,24(sp)
    80003794:	e84a                	sd	s2,16(sp)
    80003796:	e44e                	sd	s3,8(sp)
    80003798:	e052                	sd	s4,0(sp)
    8000379a:	1800                	add	s0,sp,48
    8000379c:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000379e:	47ad                	li	a5,11
    800037a0:	02b7e863          	bltu	a5,a1,800037d0 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800037a4:	02059793          	sll	a5,a1,0x20
    800037a8:	01e7d593          	srl	a1,a5,0x1e
    800037ac:	00b504b3          	add	s1,a0,a1
    800037b0:	0504a903          	lw	s2,80(s1)
    800037b4:	06091e63          	bnez	s2,80003830 <bmap+0xa4>
      addr = balloc(ip->dev);
    800037b8:	4108                	lw	a0,0(a0)
    800037ba:	00000097          	auipc	ra,0x0
    800037be:	ea0080e7          	jalr	-352(ra) # 8000365a <balloc>
    800037c2:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800037c6:	06090563          	beqz	s2,80003830 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    800037ca:	0524a823          	sw	s2,80(s1)
    800037ce:	a08d                	j	80003830 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800037d0:	ff45849b          	addw	s1,a1,-12
    800037d4:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800037d8:	0ff00793          	li	a5,255
    800037dc:	08e7e563          	bltu	a5,a4,80003866 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800037e0:	08052903          	lw	s2,128(a0)
    800037e4:	00091d63          	bnez	s2,800037fe <bmap+0x72>
      addr = balloc(ip->dev);
    800037e8:	4108                	lw	a0,0(a0)
    800037ea:	00000097          	auipc	ra,0x0
    800037ee:	e70080e7          	jalr	-400(ra) # 8000365a <balloc>
    800037f2:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800037f6:	02090d63          	beqz	s2,80003830 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800037fa:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800037fe:	85ca                	mv	a1,s2
    80003800:	0009a503          	lw	a0,0(s3)
    80003804:	00000097          	auipc	ra,0x0
    80003808:	b96080e7          	jalr	-1130(ra) # 8000339a <bread>
    8000380c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000380e:	05850793          	add	a5,a0,88
    if((addr = a[bn]) == 0){
    80003812:	02049713          	sll	a4,s1,0x20
    80003816:	01e75593          	srl	a1,a4,0x1e
    8000381a:	00b784b3          	add	s1,a5,a1
    8000381e:	0004a903          	lw	s2,0(s1)
    80003822:	02090063          	beqz	s2,80003842 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003826:	8552                	mv	a0,s4
    80003828:	00000097          	auipc	ra,0x0
    8000382c:	ca2080e7          	jalr	-862(ra) # 800034ca <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003830:	854a                	mv	a0,s2
    80003832:	70a2                	ld	ra,40(sp)
    80003834:	7402                	ld	s0,32(sp)
    80003836:	64e2                	ld	s1,24(sp)
    80003838:	6942                	ld	s2,16(sp)
    8000383a:	69a2                	ld	s3,8(sp)
    8000383c:	6a02                	ld	s4,0(sp)
    8000383e:	6145                	add	sp,sp,48
    80003840:	8082                	ret
      addr = balloc(ip->dev);
    80003842:	0009a503          	lw	a0,0(s3)
    80003846:	00000097          	auipc	ra,0x0
    8000384a:	e14080e7          	jalr	-492(ra) # 8000365a <balloc>
    8000384e:	0005091b          	sext.w	s2,a0
      if(addr){
    80003852:	fc090ae3          	beqz	s2,80003826 <bmap+0x9a>
        a[bn] = addr;
    80003856:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    8000385a:	8552                	mv	a0,s4
    8000385c:	00001097          	auipc	ra,0x1
    80003860:	ec6080e7          	jalr	-314(ra) # 80004722 <log_write>
    80003864:	b7c9                	j	80003826 <bmap+0x9a>
  panic("bmap: out of range");
    80003866:	00005517          	auipc	a0,0x5
    8000386a:	d4250513          	add	a0,a0,-702 # 800085a8 <syscalls+0x130>
    8000386e:	ffffd097          	auipc	ra,0xffffd
    80003872:	cce080e7          	jalr	-818(ra) # 8000053c <panic>

0000000080003876 <iget>:
{
    80003876:	7179                	add	sp,sp,-48
    80003878:	f406                	sd	ra,40(sp)
    8000387a:	f022                	sd	s0,32(sp)
    8000387c:	ec26                	sd	s1,24(sp)
    8000387e:	e84a                	sd	s2,16(sp)
    80003880:	e44e                	sd	s3,8(sp)
    80003882:	e052                	sd	s4,0(sp)
    80003884:	1800                	add	s0,sp,48
    80003886:	89aa                	mv	s3,a0
    80003888:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000388a:	0023c517          	auipc	a0,0x23c
    8000388e:	00e50513          	add	a0,a0,14 # 8023f898 <itable>
    80003892:	ffffd097          	auipc	ra,0xffffd
    80003896:	40a080e7          	jalr	1034(ra) # 80000c9c <acquire>
  empty = 0;
    8000389a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000389c:	0023c497          	auipc	s1,0x23c
    800038a0:	01448493          	add	s1,s1,20 # 8023f8b0 <itable+0x18>
    800038a4:	0023e697          	auipc	a3,0x23e
    800038a8:	a9c68693          	add	a3,a3,-1380 # 80241340 <log>
    800038ac:	a039                	j	800038ba <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038ae:	02090b63          	beqz	s2,800038e4 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800038b2:	08848493          	add	s1,s1,136
    800038b6:	02d48a63          	beq	s1,a3,800038ea <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800038ba:	449c                	lw	a5,8(s1)
    800038bc:	fef059e3          	blez	a5,800038ae <iget+0x38>
    800038c0:	4098                	lw	a4,0(s1)
    800038c2:	ff3716e3          	bne	a4,s3,800038ae <iget+0x38>
    800038c6:	40d8                	lw	a4,4(s1)
    800038c8:	ff4713e3          	bne	a4,s4,800038ae <iget+0x38>
      ip->ref++;
    800038cc:	2785                	addw	a5,a5,1
    800038ce:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800038d0:	0023c517          	auipc	a0,0x23c
    800038d4:	fc850513          	add	a0,a0,-56 # 8023f898 <itable>
    800038d8:	ffffd097          	auipc	ra,0xffffd
    800038dc:	478080e7          	jalr	1144(ra) # 80000d50 <release>
      return ip;
    800038e0:	8926                	mv	s2,s1
    800038e2:	a03d                	j	80003910 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038e4:	f7f9                	bnez	a5,800038b2 <iget+0x3c>
    800038e6:	8926                	mv	s2,s1
    800038e8:	b7e9                	j	800038b2 <iget+0x3c>
  if(empty == 0)
    800038ea:	02090c63          	beqz	s2,80003922 <iget+0xac>
  ip->dev = dev;
    800038ee:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800038f2:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800038f6:	4785                	li	a5,1
    800038f8:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800038fc:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003900:	0023c517          	auipc	a0,0x23c
    80003904:	f9850513          	add	a0,a0,-104 # 8023f898 <itable>
    80003908:	ffffd097          	auipc	ra,0xffffd
    8000390c:	448080e7          	jalr	1096(ra) # 80000d50 <release>
}
    80003910:	854a                	mv	a0,s2
    80003912:	70a2                	ld	ra,40(sp)
    80003914:	7402                	ld	s0,32(sp)
    80003916:	64e2                	ld	s1,24(sp)
    80003918:	6942                	ld	s2,16(sp)
    8000391a:	69a2                	ld	s3,8(sp)
    8000391c:	6a02                	ld	s4,0(sp)
    8000391e:	6145                	add	sp,sp,48
    80003920:	8082                	ret
    panic("iget: no inodes");
    80003922:	00005517          	auipc	a0,0x5
    80003926:	c9e50513          	add	a0,a0,-866 # 800085c0 <syscalls+0x148>
    8000392a:	ffffd097          	auipc	ra,0xffffd
    8000392e:	c12080e7          	jalr	-1006(ra) # 8000053c <panic>

0000000080003932 <fsinit>:
fsinit(int dev) {
    80003932:	7179                	add	sp,sp,-48
    80003934:	f406                	sd	ra,40(sp)
    80003936:	f022                	sd	s0,32(sp)
    80003938:	ec26                	sd	s1,24(sp)
    8000393a:	e84a                	sd	s2,16(sp)
    8000393c:	e44e                	sd	s3,8(sp)
    8000393e:	1800                	add	s0,sp,48
    80003940:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003942:	4585                	li	a1,1
    80003944:	00000097          	auipc	ra,0x0
    80003948:	a56080e7          	jalr	-1450(ra) # 8000339a <bread>
    8000394c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000394e:	0023c997          	auipc	s3,0x23c
    80003952:	f2a98993          	add	s3,s3,-214 # 8023f878 <sb>
    80003956:	02000613          	li	a2,32
    8000395a:	05850593          	add	a1,a0,88
    8000395e:	854e                	mv	a0,s3
    80003960:	ffffd097          	auipc	ra,0xffffd
    80003964:	494080e7          	jalr	1172(ra) # 80000df4 <memmove>
  brelse(bp);
    80003968:	8526                	mv	a0,s1
    8000396a:	00000097          	auipc	ra,0x0
    8000396e:	b60080e7          	jalr	-1184(ra) # 800034ca <brelse>
  if(sb.magic != FSMAGIC)
    80003972:	0009a703          	lw	a4,0(s3)
    80003976:	102037b7          	lui	a5,0x10203
    8000397a:	04078793          	add	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000397e:	02f71263          	bne	a4,a5,800039a2 <fsinit+0x70>
  initlog(dev, &sb);
    80003982:	0023c597          	auipc	a1,0x23c
    80003986:	ef658593          	add	a1,a1,-266 # 8023f878 <sb>
    8000398a:	854a                	mv	a0,s2
    8000398c:	00001097          	auipc	ra,0x1
    80003990:	b2c080e7          	jalr	-1236(ra) # 800044b8 <initlog>
}
    80003994:	70a2                	ld	ra,40(sp)
    80003996:	7402                	ld	s0,32(sp)
    80003998:	64e2                	ld	s1,24(sp)
    8000399a:	6942                	ld	s2,16(sp)
    8000399c:	69a2                	ld	s3,8(sp)
    8000399e:	6145                	add	sp,sp,48
    800039a0:	8082                	ret
    panic("invalid file system");
    800039a2:	00005517          	auipc	a0,0x5
    800039a6:	c2e50513          	add	a0,a0,-978 # 800085d0 <syscalls+0x158>
    800039aa:	ffffd097          	auipc	ra,0xffffd
    800039ae:	b92080e7          	jalr	-1134(ra) # 8000053c <panic>

00000000800039b2 <iinit>:
{
    800039b2:	7179                	add	sp,sp,-48
    800039b4:	f406                	sd	ra,40(sp)
    800039b6:	f022                	sd	s0,32(sp)
    800039b8:	ec26                	sd	s1,24(sp)
    800039ba:	e84a                	sd	s2,16(sp)
    800039bc:	e44e                	sd	s3,8(sp)
    800039be:	1800                	add	s0,sp,48
  initlock(&itable.lock, "itable");
    800039c0:	00005597          	auipc	a1,0x5
    800039c4:	c2858593          	add	a1,a1,-984 # 800085e8 <syscalls+0x170>
    800039c8:	0023c517          	auipc	a0,0x23c
    800039cc:	ed050513          	add	a0,a0,-304 # 8023f898 <itable>
    800039d0:	ffffd097          	auipc	ra,0xffffd
    800039d4:	23c080e7          	jalr	572(ra) # 80000c0c <initlock>
  for(i = 0; i < NINODE; i++) {
    800039d8:	0023c497          	auipc	s1,0x23c
    800039dc:	ee848493          	add	s1,s1,-280 # 8023f8c0 <itable+0x28>
    800039e0:	0023e997          	auipc	s3,0x23e
    800039e4:	97098993          	add	s3,s3,-1680 # 80241350 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800039e8:	00005917          	auipc	s2,0x5
    800039ec:	c0890913          	add	s2,s2,-1016 # 800085f0 <syscalls+0x178>
    800039f0:	85ca                	mv	a1,s2
    800039f2:	8526                	mv	a0,s1
    800039f4:	00001097          	auipc	ra,0x1
    800039f8:	e12080e7          	jalr	-494(ra) # 80004806 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800039fc:	08848493          	add	s1,s1,136
    80003a00:	ff3498e3          	bne	s1,s3,800039f0 <iinit+0x3e>
}
    80003a04:	70a2                	ld	ra,40(sp)
    80003a06:	7402                	ld	s0,32(sp)
    80003a08:	64e2                	ld	s1,24(sp)
    80003a0a:	6942                	ld	s2,16(sp)
    80003a0c:	69a2                	ld	s3,8(sp)
    80003a0e:	6145                	add	sp,sp,48
    80003a10:	8082                	ret

0000000080003a12 <ialloc>:
{
    80003a12:	7139                	add	sp,sp,-64
    80003a14:	fc06                	sd	ra,56(sp)
    80003a16:	f822                	sd	s0,48(sp)
    80003a18:	f426                	sd	s1,40(sp)
    80003a1a:	f04a                	sd	s2,32(sp)
    80003a1c:	ec4e                	sd	s3,24(sp)
    80003a1e:	e852                	sd	s4,16(sp)
    80003a20:	e456                	sd	s5,8(sp)
    80003a22:	e05a                	sd	s6,0(sp)
    80003a24:	0080                	add	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a26:	0023c717          	auipc	a4,0x23c
    80003a2a:	e5e72703          	lw	a4,-418(a4) # 8023f884 <sb+0xc>
    80003a2e:	4785                	li	a5,1
    80003a30:	04e7f863          	bgeu	a5,a4,80003a80 <ialloc+0x6e>
    80003a34:	8aaa                	mv	s5,a0
    80003a36:	8b2e                	mv	s6,a1
    80003a38:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003a3a:	0023ca17          	auipc	s4,0x23c
    80003a3e:	e3ea0a13          	add	s4,s4,-450 # 8023f878 <sb>
    80003a42:	00495593          	srl	a1,s2,0x4
    80003a46:	018a2783          	lw	a5,24(s4)
    80003a4a:	9dbd                	addw	a1,a1,a5
    80003a4c:	8556                	mv	a0,s5
    80003a4e:	00000097          	auipc	ra,0x0
    80003a52:	94c080e7          	jalr	-1716(ra) # 8000339a <bread>
    80003a56:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003a58:	05850993          	add	s3,a0,88
    80003a5c:	00f97793          	and	a5,s2,15
    80003a60:	079a                	sll	a5,a5,0x6
    80003a62:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003a64:	00099783          	lh	a5,0(s3)
    80003a68:	cf9d                	beqz	a5,80003aa6 <ialloc+0x94>
    brelse(bp);
    80003a6a:	00000097          	auipc	ra,0x0
    80003a6e:	a60080e7          	jalr	-1440(ra) # 800034ca <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a72:	0905                	add	s2,s2,1
    80003a74:	00ca2703          	lw	a4,12(s4)
    80003a78:	0009079b          	sext.w	a5,s2
    80003a7c:	fce7e3e3          	bltu	a5,a4,80003a42 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80003a80:	00005517          	auipc	a0,0x5
    80003a84:	b7850513          	add	a0,a0,-1160 # 800085f8 <syscalls+0x180>
    80003a88:	ffffd097          	auipc	ra,0xffffd
    80003a8c:	afe080e7          	jalr	-1282(ra) # 80000586 <printf>
  return 0;
    80003a90:	4501                	li	a0,0
}
    80003a92:	70e2                	ld	ra,56(sp)
    80003a94:	7442                	ld	s0,48(sp)
    80003a96:	74a2                	ld	s1,40(sp)
    80003a98:	7902                	ld	s2,32(sp)
    80003a9a:	69e2                	ld	s3,24(sp)
    80003a9c:	6a42                	ld	s4,16(sp)
    80003a9e:	6aa2                	ld	s5,8(sp)
    80003aa0:	6b02                	ld	s6,0(sp)
    80003aa2:	6121                	add	sp,sp,64
    80003aa4:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003aa6:	04000613          	li	a2,64
    80003aaa:	4581                	li	a1,0
    80003aac:	854e                	mv	a0,s3
    80003aae:	ffffd097          	auipc	ra,0xffffd
    80003ab2:	2ea080e7          	jalr	746(ra) # 80000d98 <memset>
      dip->type = type;
    80003ab6:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003aba:	8526                	mv	a0,s1
    80003abc:	00001097          	auipc	ra,0x1
    80003ac0:	c66080e7          	jalr	-922(ra) # 80004722 <log_write>
      brelse(bp);
    80003ac4:	8526                	mv	a0,s1
    80003ac6:	00000097          	auipc	ra,0x0
    80003aca:	a04080e7          	jalr	-1532(ra) # 800034ca <brelse>
      return iget(dev, inum);
    80003ace:	0009059b          	sext.w	a1,s2
    80003ad2:	8556                	mv	a0,s5
    80003ad4:	00000097          	auipc	ra,0x0
    80003ad8:	da2080e7          	jalr	-606(ra) # 80003876 <iget>
    80003adc:	bf5d                	j	80003a92 <ialloc+0x80>

0000000080003ade <iupdate>:
{
    80003ade:	1101                	add	sp,sp,-32
    80003ae0:	ec06                	sd	ra,24(sp)
    80003ae2:	e822                	sd	s0,16(sp)
    80003ae4:	e426                	sd	s1,8(sp)
    80003ae6:	e04a                	sd	s2,0(sp)
    80003ae8:	1000                	add	s0,sp,32
    80003aea:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003aec:	415c                	lw	a5,4(a0)
    80003aee:	0047d79b          	srlw	a5,a5,0x4
    80003af2:	0023c597          	auipc	a1,0x23c
    80003af6:	d9e5a583          	lw	a1,-610(a1) # 8023f890 <sb+0x18>
    80003afa:	9dbd                	addw	a1,a1,a5
    80003afc:	4108                	lw	a0,0(a0)
    80003afe:	00000097          	auipc	ra,0x0
    80003b02:	89c080e7          	jalr	-1892(ra) # 8000339a <bread>
    80003b06:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b08:	05850793          	add	a5,a0,88
    80003b0c:	40d8                	lw	a4,4(s1)
    80003b0e:	8b3d                	and	a4,a4,15
    80003b10:	071a                	sll	a4,a4,0x6
    80003b12:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003b14:	04449703          	lh	a4,68(s1)
    80003b18:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003b1c:	04649703          	lh	a4,70(s1)
    80003b20:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003b24:	04849703          	lh	a4,72(s1)
    80003b28:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003b2c:	04a49703          	lh	a4,74(s1)
    80003b30:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003b34:	44f8                	lw	a4,76(s1)
    80003b36:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003b38:	03400613          	li	a2,52
    80003b3c:	05048593          	add	a1,s1,80
    80003b40:	00c78513          	add	a0,a5,12
    80003b44:	ffffd097          	auipc	ra,0xffffd
    80003b48:	2b0080e7          	jalr	688(ra) # 80000df4 <memmove>
  log_write(bp);
    80003b4c:	854a                	mv	a0,s2
    80003b4e:	00001097          	auipc	ra,0x1
    80003b52:	bd4080e7          	jalr	-1068(ra) # 80004722 <log_write>
  brelse(bp);
    80003b56:	854a                	mv	a0,s2
    80003b58:	00000097          	auipc	ra,0x0
    80003b5c:	972080e7          	jalr	-1678(ra) # 800034ca <brelse>
}
    80003b60:	60e2                	ld	ra,24(sp)
    80003b62:	6442                	ld	s0,16(sp)
    80003b64:	64a2                	ld	s1,8(sp)
    80003b66:	6902                	ld	s2,0(sp)
    80003b68:	6105                	add	sp,sp,32
    80003b6a:	8082                	ret

0000000080003b6c <idup>:
{
    80003b6c:	1101                	add	sp,sp,-32
    80003b6e:	ec06                	sd	ra,24(sp)
    80003b70:	e822                	sd	s0,16(sp)
    80003b72:	e426                	sd	s1,8(sp)
    80003b74:	1000                	add	s0,sp,32
    80003b76:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b78:	0023c517          	auipc	a0,0x23c
    80003b7c:	d2050513          	add	a0,a0,-736 # 8023f898 <itable>
    80003b80:	ffffd097          	auipc	ra,0xffffd
    80003b84:	11c080e7          	jalr	284(ra) # 80000c9c <acquire>
  ip->ref++;
    80003b88:	449c                	lw	a5,8(s1)
    80003b8a:	2785                	addw	a5,a5,1
    80003b8c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b8e:	0023c517          	auipc	a0,0x23c
    80003b92:	d0a50513          	add	a0,a0,-758 # 8023f898 <itable>
    80003b96:	ffffd097          	auipc	ra,0xffffd
    80003b9a:	1ba080e7          	jalr	442(ra) # 80000d50 <release>
}
    80003b9e:	8526                	mv	a0,s1
    80003ba0:	60e2                	ld	ra,24(sp)
    80003ba2:	6442                	ld	s0,16(sp)
    80003ba4:	64a2                	ld	s1,8(sp)
    80003ba6:	6105                	add	sp,sp,32
    80003ba8:	8082                	ret

0000000080003baa <ilock>:
{
    80003baa:	1101                	add	sp,sp,-32
    80003bac:	ec06                	sd	ra,24(sp)
    80003bae:	e822                	sd	s0,16(sp)
    80003bb0:	e426                	sd	s1,8(sp)
    80003bb2:	e04a                	sd	s2,0(sp)
    80003bb4:	1000                	add	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003bb6:	c115                	beqz	a0,80003bda <ilock+0x30>
    80003bb8:	84aa                	mv	s1,a0
    80003bba:	451c                	lw	a5,8(a0)
    80003bbc:	00f05f63          	blez	a5,80003bda <ilock+0x30>
  acquiresleep(&ip->lock);
    80003bc0:	0541                	add	a0,a0,16
    80003bc2:	00001097          	auipc	ra,0x1
    80003bc6:	c7e080e7          	jalr	-898(ra) # 80004840 <acquiresleep>
  if(ip->valid == 0){
    80003bca:	40bc                	lw	a5,64(s1)
    80003bcc:	cf99                	beqz	a5,80003bea <ilock+0x40>
}
    80003bce:	60e2                	ld	ra,24(sp)
    80003bd0:	6442                	ld	s0,16(sp)
    80003bd2:	64a2                	ld	s1,8(sp)
    80003bd4:	6902                	ld	s2,0(sp)
    80003bd6:	6105                	add	sp,sp,32
    80003bd8:	8082                	ret
    panic("ilock");
    80003bda:	00005517          	auipc	a0,0x5
    80003bde:	a3650513          	add	a0,a0,-1482 # 80008610 <syscalls+0x198>
    80003be2:	ffffd097          	auipc	ra,0xffffd
    80003be6:	95a080e7          	jalr	-1702(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003bea:	40dc                	lw	a5,4(s1)
    80003bec:	0047d79b          	srlw	a5,a5,0x4
    80003bf0:	0023c597          	auipc	a1,0x23c
    80003bf4:	ca05a583          	lw	a1,-864(a1) # 8023f890 <sb+0x18>
    80003bf8:	9dbd                	addw	a1,a1,a5
    80003bfa:	4088                	lw	a0,0(s1)
    80003bfc:	fffff097          	auipc	ra,0xfffff
    80003c00:	79e080e7          	jalr	1950(ra) # 8000339a <bread>
    80003c04:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c06:	05850593          	add	a1,a0,88
    80003c0a:	40dc                	lw	a5,4(s1)
    80003c0c:	8bbd                	and	a5,a5,15
    80003c0e:	079a                	sll	a5,a5,0x6
    80003c10:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003c12:	00059783          	lh	a5,0(a1)
    80003c16:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003c1a:	00259783          	lh	a5,2(a1)
    80003c1e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003c22:	00459783          	lh	a5,4(a1)
    80003c26:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003c2a:	00659783          	lh	a5,6(a1)
    80003c2e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003c32:	459c                	lw	a5,8(a1)
    80003c34:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003c36:	03400613          	li	a2,52
    80003c3a:	05b1                	add	a1,a1,12
    80003c3c:	05048513          	add	a0,s1,80
    80003c40:	ffffd097          	auipc	ra,0xffffd
    80003c44:	1b4080e7          	jalr	436(ra) # 80000df4 <memmove>
    brelse(bp);
    80003c48:	854a                	mv	a0,s2
    80003c4a:	00000097          	auipc	ra,0x0
    80003c4e:	880080e7          	jalr	-1920(ra) # 800034ca <brelse>
    ip->valid = 1;
    80003c52:	4785                	li	a5,1
    80003c54:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003c56:	04449783          	lh	a5,68(s1)
    80003c5a:	fbb5                	bnez	a5,80003bce <ilock+0x24>
      panic("ilock: no type");
    80003c5c:	00005517          	auipc	a0,0x5
    80003c60:	9bc50513          	add	a0,a0,-1604 # 80008618 <syscalls+0x1a0>
    80003c64:	ffffd097          	auipc	ra,0xffffd
    80003c68:	8d8080e7          	jalr	-1832(ra) # 8000053c <panic>

0000000080003c6c <iunlock>:
{
    80003c6c:	1101                	add	sp,sp,-32
    80003c6e:	ec06                	sd	ra,24(sp)
    80003c70:	e822                	sd	s0,16(sp)
    80003c72:	e426                	sd	s1,8(sp)
    80003c74:	e04a                	sd	s2,0(sp)
    80003c76:	1000                	add	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003c78:	c905                	beqz	a0,80003ca8 <iunlock+0x3c>
    80003c7a:	84aa                	mv	s1,a0
    80003c7c:	01050913          	add	s2,a0,16
    80003c80:	854a                	mv	a0,s2
    80003c82:	00001097          	auipc	ra,0x1
    80003c86:	c58080e7          	jalr	-936(ra) # 800048da <holdingsleep>
    80003c8a:	cd19                	beqz	a0,80003ca8 <iunlock+0x3c>
    80003c8c:	449c                	lw	a5,8(s1)
    80003c8e:	00f05d63          	blez	a5,80003ca8 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003c92:	854a                	mv	a0,s2
    80003c94:	00001097          	auipc	ra,0x1
    80003c98:	c02080e7          	jalr	-1022(ra) # 80004896 <releasesleep>
}
    80003c9c:	60e2                	ld	ra,24(sp)
    80003c9e:	6442                	ld	s0,16(sp)
    80003ca0:	64a2                	ld	s1,8(sp)
    80003ca2:	6902                	ld	s2,0(sp)
    80003ca4:	6105                	add	sp,sp,32
    80003ca6:	8082                	ret
    panic("iunlock");
    80003ca8:	00005517          	auipc	a0,0x5
    80003cac:	98050513          	add	a0,a0,-1664 # 80008628 <syscalls+0x1b0>
    80003cb0:	ffffd097          	auipc	ra,0xffffd
    80003cb4:	88c080e7          	jalr	-1908(ra) # 8000053c <panic>

0000000080003cb8 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003cb8:	7179                	add	sp,sp,-48
    80003cba:	f406                	sd	ra,40(sp)
    80003cbc:	f022                	sd	s0,32(sp)
    80003cbe:	ec26                	sd	s1,24(sp)
    80003cc0:	e84a                	sd	s2,16(sp)
    80003cc2:	e44e                	sd	s3,8(sp)
    80003cc4:	e052                	sd	s4,0(sp)
    80003cc6:	1800                	add	s0,sp,48
    80003cc8:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003cca:	05050493          	add	s1,a0,80
    80003cce:	08050913          	add	s2,a0,128
    80003cd2:	a021                	j	80003cda <itrunc+0x22>
    80003cd4:	0491                	add	s1,s1,4
    80003cd6:	01248d63          	beq	s1,s2,80003cf0 <itrunc+0x38>
    if(ip->addrs[i]){
    80003cda:	408c                	lw	a1,0(s1)
    80003cdc:	dde5                	beqz	a1,80003cd4 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003cde:	0009a503          	lw	a0,0(s3)
    80003ce2:	00000097          	auipc	ra,0x0
    80003ce6:	8fc080e7          	jalr	-1796(ra) # 800035de <bfree>
      ip->addrs[i] = 0;
    80003cea:	0004a023          	sw	zero,0(s1)
    80003cee:	b7dd                	j	80003cd4 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003cf0:	0809a583          	lw	a1,128(s3)
    80003cf4:	e185                	bnez	a1,80003d14 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003cf6:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003cfa:	854e                	mv	a0,s3
    80003cfc:	00000097          	auipc	ra,0x0
    80003d00:	de2080e7          	jalr	-542(ra) # 80003ade <iupdate>
}
    80003d04:	70a2                	ld	ra,40(sp)
    80003d06:	7402                	ld	s0,32(sp)
    80003d08:	64e2                	ld	s1,24(sp)
    80003d0a:	6942                	ld	s2,16(sp)
    80003d0c:	69a2                	ld	s3,8(sp)
    80003d0e:	6a02                	ld	s4,0(sp)
    80003d10:	6145                	add	sp,sp,48
    80003d12:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003d14:	0009a503          	lw	a0,0(s3)
    80003d18:	fffff097          	auipc	ra,0xfffff
    80003d1c:	682080e7          	jalr	1666(ra) # 8000339a <bread>
    80003d20:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003d22:	05850493          	add	s1,a0,88
    80003d26:	45850913          	add	s2,a0,1112
    80003d2a:	a021                	j	80003d32 <itrunc+0x7a>
    80003d2c:	0491                	add	s1,s1,4
    80003d2e:	01248b63          	beq	s1,s2,80003d44 <itrunc+0x8c>
      if(a[j])
    80003d32:	408c                	lw	a1,0(s1)
    80003d34:	dde5                	beqz	a1,80003d2c <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003d36:	0009a503          	lw	a0,0(s3)
    80003d3a:	00000097          	auipc	ra,0x0
    80003d3e:	8a4080e7          	jalr	-1884(ra) # 800035de <bfree>
    80003d42:	b7ed                	j	80003d2c <itrunc+0x74>
    brelse(bp);
    80003d44:	8552                	mv	a0,s4
    80003d46:	fffff097          	auipc	ra,0xfffff
    80003d4a:	784080e7          	jalr	1924(ra) # 800034ca <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003d4e:	0809a583          	lw	a1,128(s3)
    80003d52:	0009a503          	lw	a0,0(s3)
    80003d56:	00000097          	auipc	ra,0x0
    80003d5a:	888080e7          	jalr	-1912(ra) # 800035de <bfree>
    ip->addrs[NDIRECT] = 0;
    80003d5e:	0809a023          	sw	zero,128(s3)
    80003d62:	bf51                	j	80003cf6 <itrunc+0x3e>

0000000080003d64 <iput>:
{
    80003d64:	1101                	add	sp,sp,-32
    80003d66:	ec06                	sd	ra,24(sp)
    80003d68:	e822                	sd	s0,16(sp)
    80003d6a:	e426                	sd	s1,8(sp)
    80003d6c:	e04a                	sd	s2,0(sp)
    80003d6e:	1000                	add	s0,sp,32
    80003d70:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d72:	0023c517          	auipc	a0,0x23c
    80003d76:	b2650513          	add	a0,a0,-1242 # 8023f898 <itable>
    80003d7a:	ffffd097          	auipc	ra,0xffffd
    80003d7e:	f22080e7          	jalr	-222(ra) # 80000c9c <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d82:	4498                	lw	a4,8(s1)
    80003d84:	4785                	li	a5,1
    80003d86:	02f70363          	beq	a4,a5,80003dac <iput+0x48>
  ip->ref--;
    80003d8a:	449c                	lw	a5,8(s1)
    80003d8c:	37fd                	addw	a5,a5,-1
    80003d8e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d90:	0023c517          	auipc	a0,0x23c
    80003d94:	b0850513          	add	a0,a0,-1272 # 8023f898 <itable>
    80003d98:	ffffd097          	auipc	ra,0xffffd
    80003d9c:	fb8080e7          	jalr	-72(ra) # 80000d50 <release>
}
    80003da0:	60e2                	ld	ra,24(sp)
    80003da2:	6442                	ld	s0,16(sp)
    80003da4:	64a2                	ld	s1,8(sp)
    80003da6:	6902                	ld	s2,0(sp)
    80003da8:	6105                	add	sp,sp,32
    80003daa:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003dac:	40bc                	lw	a5,64(s1)
    80003dae:	dff1                	beqz	a5,80003d8a <iput+0x26>
    80003db0:	04a49783          	lh	a5,74(s1)
    80003db4:	fbf9                	bnez	a5,80003d8a <iput+0x26>
    acquiresleep(&ip->lock);
    80003db6:	01048913          	add	s2,s1,16
    80003dba:	854a                	mv	a0,s2
    80003dbc:	00001097          	auipc	ra,0x1
    80003dc0:	a84080e7          	jalr	-1404(ra) # 80004840 <acquiresleep>
    release(&itable.lock);
    80003dc4:	0023c517          	auipc	a0,0x23c
    80003dc8:	ad450513          	add	a0,a0,-1324 # 8023f898 <itable>
    80003dcc:	ffffd097          	auipc	ra,0xffffd
    80003dd0:	f84080e7          	jalr	-124(ra) # 80000d50 <release>
    itrunc(ip);
    80003dd4:	8526                	mv	a0,s1
    80003dd6:	00000097          	auipc	ra,0x0
    80003dda:	ee2080e7          	jalr	-286(ra) # 80003cb8 <itrunc>
    ip->type = 0;
    80003dde:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003de2:	8526                	mv	a0,s1
    80003de4:	00000097          	auipc	ra,0x0
    80003de8:	cfa080e7          	jalr	-774(ra) # 80003ade <iupdate>
    ip->valid = 0;
    80003dec:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003df0:	854a                	mv	a0,s2
    80003df2:	00001097          	auipc	ra,0x1
    80003df6:	aa4080e7          	jalr	-1372(ra) # 80004896 <releasesleep>
    acquire(&itable.lock);
    80003dfa:	0023c517          	auipc	a0,0x23c
    80003dfe:	a9e50513          	add	a0,a0,-1378 # 8023f898 <itable>
    80003e02:	ffffd097          	auipc	ra,0xffffd
    80003e06:	e9a080e7          	jalr	-358(ra) # 80000c9c <acquire>
    80003e0a:	b741                	j	80003d8a <iput+0x26>

0000000080003e0c <iunlockput>:
{
    80003e0c:	1101                	add	sp,sp,-32
    80003e0e:	ec06                	sd	ra,24(sp)
    80003e10:	e822                	sd	s0,16(sp)
    80003e12:	e426                	sd	s1,8(sp)
    80003e14:	1000                	add	s0,sp,32
    80003e16:	84aa                	mv	s1,a0
  iunlock(ip);
    80003e18:	00000097          	auipc	ra,0x0
    80003e1c:	e54080e7          	jalr	-428(ra) # 80003c6c <iunlock>
  iput(ip);
    80003e20:	8526                	mv	a0,s1
    80003e22:	00000097          	auipc	ra,0x0
    80003e26:	f42080e7          	jalr	-190(ra) # 80003d64 <iput>
}
    80003e2a:	60e2                	ld	ra,24(sp)
    80003e2c:	6442                	ld	s0,16(sp)
    80003e2e:	64a2                	ld	s1,8(sp)
    80003e30:	6105                	add	sp,sp,32
    80003e32:	8082                	ret

0000000080003e34 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003e34:	1141                	add	sp,sp,-16
    80003e36:	e422                	sd	s0,8(sp)
    80003e38:	0800                	add	s0,sp,16
  st->dev = ip->dev;
    80003e3a:	411c                	lw	a5,0(a0)
    80003e3c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003e3e:	415c                	lw	a5,4(a0)
    80003e40:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003e42:	04451783          	lh	a5,68(a0)
    80003e46:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e4a:	04a51783          	lh	a5,74(a0)
    80003e4e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003e52:	04c56783          	lwu	a5,76(a0)
    80003e56:	e99c                	sd	a5,16(a1)
}
    80003e58:	6422                	ld	s0,8(sp)
    80003e5a:	0141                	add	sp,sp,16
    80003e5c:	8082                	ret

0000000080003e5e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e5e:	457c                	lw	a5,76(a0)
    80003e60:	0ed7e963          	bltu	a5,a3,80003f52 <readi+0xf4>
{
    80003e64:	7159                	add	sp,sp,-112
    80003e66:	f486                	sd	ra,104(sp)
    80003e68:	f0a2                	sd	s0,96(sp)
    80003e6a:	eca6                	sd	s1,88(sp)
    80003e6c:	e8ca                	sd	s2,80(sp)
    80003e6e:	e4ce                	sd	s3,72(sp)
    80003e70:	e0d2                	sd	s4,64(sp)
    80003e72:	fc56                	sd	s5,56(sp)
    80003e74:	f85a                	sd	s6,48(sp)
    80003e76:	f45e                	sd	s7,40(sp)
    80003e78:	f062                	sd	s8,32(sp)
    80003e7a:	ec66                	sd	s9,24(sp)
    80003e7c:	e86a                	sd	s10,16(sp)
    80003e7e:	e46e                	sd	s11,8(sp)
    80003e80:	1880                	add	s0,sp,112
    80003e82:	8b2a                	mv	s6,a0
    80003e84:	8bae                	mv	s7,a1
    80003e86:	8a32                	mv	s4,a2
    80003e88:	84b6                	mv	s1,a3
    80003e8a:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003e8c:	9f35                	addw	a4,a4,a3
    return 0;
    80003e8e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003e90:	0ad76063          	bltu	a4,a3,80003f30 <readi+0xd2>
  if(off + n > ip->size)
    80003e94:	00e7f463          	bgeu	a5,a4,80003e9c <readi+0x3e>
    n = ip->size - off;
    80003e98:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e9c:	0a0a8963          	beqz	s5,80003f4e <readi+0xf0>
    80003ea0:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ea2:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003ea6:	5c7d                	li	s8,-1
    80003ea8:	a82d                	j	80003ee2 <readi+0x84>
    80003eaa:	020d1d93          	sll	s11,s10,0x20
    80003eae:	020ddd93          	srl	s11,s11,0x20
    80003eb2:	05890613          	add	a2,s2,88
    80003eb6:	86ee                	mv	a3,s11
    80003eb8:	963a                	add	a2,a2,a4
    80003eba:	85d2                	mv	a1,s4
    80003ebc:	855e                	mv	a0,s7
    80003ebe:	fffff097          	auipc	ra,0xfffff
    80003ec2:	84c080e7          	jalr	-1972(ra) # 8000270a <either_copyout>
    80003ec6:	05850d63          	beq	a0,s8,80003f20 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003eca:	854a                	mv	a0,s2
    80003ecc:	fffff097          	auipc	ra,0xfffff
    80003ed0:	5fe080e7          	jalr	1534(ra) # 800034ca <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ed4:	013d09bb          	addw	s3,s10,s3
    80003ed8:	009d04bb          	addw	s1,s10,s1
    80003edc:	9a6e                	add	s4,s4,s11
    80003ede:	0559f763          	bgeu	s3,s5,80003f2c <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003ee2:	00a4d59b          	srlw	a1,s1,0xa
    80003ee6:	855a                	mv	a0,s6
    80003ee8:	00000097          	auipc	ra,0x0
    80003eec:	8a4080e7          	jalr	-1884(ra) # 8000378c <bmap>
    80003ef0:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003ef4:	cd85                	beqz	a1,80003f2c <readi+0xce>
    bp = bread(ip->dev, addr);
    80003ef6:	000b2503          	lw	a0,0(s6)
    80003efa:	fffff097          	auipc	ra,0xfffff
    80003efe:	4a0080e7          	jalr	1184(ra) # 8000339a <bread>
    80003f02:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f04:	3ff4f713          	and	a4,s1,1023
    80003f08:	40ec87bb          	subw	a5,s9,a4
    80003f0c:	413a86bb          	subw	a3,s5,s3
    80003f10:	8d3e                	mv	s10,a5
    80003f12:	2781                	sext.w	a5,a5
    80003f14:	0006861b          	sext.w	a2,a3
    80003f18:	f8f679e3          	bgeu	a2,a5,80003eaa <readi+0x4c>
    80003f1c:	8d36                	mv	s10,a3
    80003f1e:	b771                	j	80003eaa <readi+0x4c>
      brelse(bp);
    80003f20:	854a                	mv	a0,s2
    80003f22:	fffff097          	auipc	ra,0xfffff
    80003f26:	5a8080e7          	jalr	1448(ra) # 800034ca <brelse>
      tot = -1;
    80003f2a:	59fd                	li	s3,-1
  }
  return tot;
    80003f2c:	0009851b          	sext.w	a0,s3
}
    80003f30:	70a6                	ld	ra,104(sp)
    80003f32:	7406                	ld	s0,96(sp)
    80003f34:	64e6                	ld	s1,88(sp)
    80003f36:	6946                	ld	s2,80(sp)
    80003f38:	69a6                	ld	s3,72(sp)
    80003f3a:	6a06                	ld	s4,64(sp)
    80003f3c:	7ae2                	ld	s5,56(sp)
    80003f3e:	7b42                	ld	s6,48(sp)
    80003f40:	7ba2                	ld	s7,40(sp)
    80003f42:	7c02                	ld	s8,32(sp)
    80003f44:	6ce2                	ld	s9,24(sp)
    80003f46:	6d42                	ld	s10,16(sp)
    80003f48:	6da2                	ld	s11,8(sp)
    80003f4a:	6165                	add	sp,sp,112
    80003f4c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f4e:	89d6                	mv	s3,s5
    80003f50:	bff1                	j	80003f2c <readi+0xce>
    return 0;
    80003f52:	4501                	li	a0,0
}
    80003f54:	8082                	ret

0000000080003f56 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f56:	457c                	lw	a5,76(a0)
    80003f58:	10d7e863          	bltu	a5,a3,80004068 <writei+0x112>
{
    80003f5c:	7159                	add	sp,sp,-112
    80003f5e:	f486                	sd	ra,104(sp)
    80003f60:	f0a2                	sd	s0,96(sp)
    80003f62:	eca6                	sd	s1,88(sp)
    80003f64:	e8ca                	sd	s2,80(sp)
    80003f66:	e4ce                	sd	s3,72(sp)
    80003f68:	e0d2                	sd	s4,64(sp)
    80003f6a:	fc56                	sd	s5,56(sp)
    80003f6c:	f85a                	sd	s6,48(sp)
    80003f6e:	f45e                	sd	s7,40(sp)
    80003f70:	f062                	sd	s8,32(sp)
    80003f72:	ec66                	sd	s9,24(sp)
    80003f74:	e86a                	sd	s10,16(sp)
    80003f76:	e46e                	sd	s11,8(sp)
    80003f78:	1880                	add	s0,sp,112
    80003f7a:	8aaa                	mv	s5,a0
    80003f7c:	8bae                	mv	s7,a1
    80003f7e:	8a32                	mv	s4,a2
    80003f80:	8936                	mv	s2,a3
    80003f82:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003f84:	00e687bb          	addw	a5,a3,a4
    80003f88:	0ed7e263          	bltu	a5,a3,8000406c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003f8c:	00043737          	lui	a4,0x43
    80003f90:	0ef76063          	bltu	a4,a5,80004070 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f94:	0c0b0863          	beqz	s6,80004064 <writei+0x10e>
    80003f98:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f9a:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003f9e:	5c7d                	li	s8,-1
    80003fa0:	a091                	j	80003fe4 <writei+0x8e>
    80003fa2:	020d1d93          	sll	s11,s10,0x20
    80003fa6:	020ddd93          	srl	s11,s11,0x20
    80003faa:	05848513          	add	a0,s1,88
    80003fae:	86ee                	mv	a3,s11
    80003fb0:	8652                	mv	a2,s4
    80003fb2:	85de                	mv	a1,s7
    80003fb4:	953a                	add	a0,a0,a4
    80003fb6:	ffffe097          	auipc	ra,0xffffe
    80003fba:	7aa080e7          	jalr	1962(ra) # 80002760 <either_copyin>
    80003fbe:	07850263          	beq	a0,s8,80004022 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003fc2:	8526                	mv	a0,s1
    80003fc4:	00000097          	auipc	ra,0x0
    80003fc8:	75e080e7          	jalr	1886(ra) # 80004722 <log_write>
    brelse(bp);
    80003fcc:	8526                	mv	a0,s1
    80003fce:	fffff097          	auipc	ra,0xfffff
    80003fd2:	4fc080e7          	jalr	1276(ra) # 800034ca <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fd6:	013d09bb          	addw	s3,s10,s3
    80003fda:	012d093b          	addw	s2,s10,s2
    80003fde:	9a6e                	add	s4,s4,s11
    80003fe0:	0569f663          	bgeu	s3,s6,8000402c <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003fe4:	00a9559b          	srlw	a1,s2,0xa
    80003fe8:	8556                	mv	a0,s5
    80003fea:	fffff097          	auipc	ra,0xfffff
    80003fee:	7a2080e7          	jalr	1954(ra) # 8000378c <bmap>
    80003ff2:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003ff6:	c99d                	beqz	a1,8000402c <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003ff8:	000aa503          	lw	a0,0(s5)
    80003ffc:	fffff097          	auipc	ra,0xfffff
    80004000:	39e080e7          	jalr	926(ra) # 8000339a <bread>
    80004004:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004006:	3ff97713          	and	a4,s2,1023
    8000400a:	40ec87bb          	subw	a5,s9,a4
    8000400e:	413b06bb          	subw	a3,s6,s3
    80004012:	8d3e                	mv	s10,a5
    80004014:	2781                	sext.w	a5,a5
    80004016:	0006861b          	sext.w	a2,a3
    8000401a:	f8f674e3          	bgeu	a2,a5,80003fa2 <writei+0x4c>
    8000401e:	8d36                	mv	s10,a3
    80004020:	b749                	j	80003fa2 <writei+0x4c>
      brelse(bp);
    80004022:	8526                	mv	a0,s1
    80004024:	fffff097          	auipc	ra,0xfffff
    80004028:	4a6080e7          	jalr	1190(ra) # 800034ca <brelse>
  }

  if(off > ip->size)
    8000402c:	04caa783          	lw	a5,76(s5)
    80004030:	0127f463          	bgeu	a5,s2,80004038 <writei+0xe2>
    ip->size = off;
    80004034:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004038:	8556                	mv	a0,s5
    8000403a:	00000097          	auipc	ra,0x0
    8000403e:	aa4080e7          	jalr	-1372(ra) # 80003ade <iupdate>

  return tot;
    80004042:	0009851b          	sext.w	a0,s3
}
    80004046:	70a6                	ld	ra,104(sp)
    80004048:	7406                	ld	s0,96(sp)
    8000404a:	64e6                	ld	s1,88(sp)
    8000404c:	6946                	ld	s2,80(sp)
    8000404e:	69a6                	ld	s3,72(sp)
    80004050:	6a06                	ld	s4,64(sp)
    80004052:	7ae2                	ld	s5,56(sp)
    80004054:	7b42                	ld	s6,48(sp)
    80004056:	7ba2                	ld	s7,40(sp)
    80004058:	7c02                	ld	s8,32(sp)
    8000405a:	6ce2                	ld	s9,24(sp)
    8000405c:	6d42                	ld	s10,16(sp)
    8000405e:	6da2                	ld	s11,8(sp)
    80004060:	6165                	add	sp,sp,112
    80004062:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004064:	89da                	mv	s3,s6
    80004066:	bfc9                	j	80004038 <writei+0xe2>
    return -1;
    80004068:	557d                	li	a0,-1
}
    8000406a:	8082                	ret
    return -1;
    8000406c:	557d                	li	a0,-1
    8000406e:	bfe1                	j	80004046 <writei+0xf0>
    return -1;
    80004070:	557d                	li	a0,-1
    80004072:	bfd1                	j	80004046 <writei+0xf0>

0000000080004074 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004074:	1141                	add	sp,sp,-16
    80004076:	e406                	sd	ra,8(sp)
    80004078:	e022                	sd	s0,0(sp)
    8000407a:	0800                	add	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000407c:	4639                	li	a2,14
    8000407e:	ffffd097          	auipc	ra,0xffffd
    80004082:	dea080e7          	jalr	-534(ra) # 80000e68 <strncmp>
}
    80004086:	60a2                	ld	ra,8(sp)
    80004088:	6402                	ld	s0,0(sp)
    8000408a:	0141                	add	sp,sp,16
    8000408c:	8082                	ret

000000008000408e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000408e:	7139                	add	sp,sp,-64
    80004090:	fc06                	sd	ra,56(sp)
    80004092:	f822                	sd	s0,48(sp)
    80004094:	f426                	sd	s1,40(sp)
    80004096:	f04a                	sd	s2,32(sp)
    80004098:	ec4e                	sd	s3,24(sp)
    8000409a:	e852                	sd	s4,16(sp)
    8000409c:	0080                	add	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000409e:	04451703          	lh	a4,68(a0)
    800040a2:	4785                	li	a5,1
    800040a4:	00f71a63          	bne	a4,a5,800040b8 <dirlookup+0x2a>
    800040a8:	892a                	mv	s2,a0
    800040aa:	89ae                	mv	s3,a1
    800040ac:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800040ae:	457c                	lw	a5,76(a0)
    800040b0:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800040b2:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040b4:	e79d                	bnez	a5,800040e2 <dirlookup+0x54>
    800040b6:	a8a5                	j	8000412e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800040b8:	00004517          	auipc	a0,0x4
    800040bc:	57850513          	add	a0,a0,1400 # 80008630 <syscalls+0x1b8>
    800040c0:	ffffc097          	auipc	ra,0xffffc
    800040c4:	47c080e7          	jalr	1148(ra) # 8000053c <panic>
      panic("dirlookup read");
    800040c8:	00004517          	auipc	a0,0x4
    800040cc:	58050513          	add	a0,a0,1408 # 80008648 <syscalls+0x1d0>
    800040d0:	ffffc097          	auipc	ra,0xffffc
    800040d4:	46c080e7          	jalr	1132(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040d8:	24c1                	addw	s1,s1,16
    800040da:	04c92783          	lw	a5,76(s2)
    800040de:	04f4f763          	bgeu	s1,a5,8000412c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040e2:	4741                	li	a4,16
    800040e4:	86a6                	mv	a3,s1
    800040e6:	fc040613          	add	a2,s0,-64
    800040ea:	4581                	li	a1,0
    800040ec:	854a                	mv	a0,s2
    800040ee:	00000097          	auipc	ra,0x0
    800040f2:	d70080e7          	jalr	-656(ra) # 80003e5e <readi>
    800040f6:	47c1                	li	a5,16
    800040f8:	fcf518e3          	bne	a0,a5,800040c8 <dirlookup+0x3a>
    if(de.inum == 0)
    800040fc:	fc045783          	lhu	a5,-64(s0)
    80004100:	dfe1                	beqz	a5,800040d8 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004102:	fc240593          	add	a1,s0,-62
    80004106:	854e                	mv	a0,s3
    80004108:	00000097          	auipc	ra,0x0
    8000410c:	f6c080e7          	jalr	-148(ra) # 80004074 <namecmp>
    80004110:	f561                	bnez	a0,800040d8 <dirlookup+0x4a>
      if(poff)
    80004112:	000a0463          	beqz	s4,8000411a <dirlookup+0x8c>
        *poff = off;
    80004116:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000411a:	fc045583          	lhu	a1,-64(s0)
    8000411e:	00092503          	lw	a0,0(s2)
    80004122:	fffff097          	auipc	ra,0xfffff
    80004126:	754080e7          	jalr	1876(ra) # 80003876 <iget>
    8000412a:	a011                	j	8000412e <dirlookup+0xa0>
  return 0;
    8000412c:	4501                	li	a0,0
}
    8000412e:	70e2                	ld	ra,56(sp)
    80004130:	7442                	ld	s0,48(sp)
    80004132:	74a2                	ld	s1,40(sp)
    80004134:	7902                	ld	s2,32(sp)
    80004136:	69e2                	ld	s3,24(sp)
    80004138:	6a42                	ld	s4,16(sp)
    8000413a:	6121                	add	sp,sp,64
    8000413c:	8082                	ret

000000008000413e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000413e:	711d                	add	sp,sp,-96
    80004140:	ec86                	sd	ra,88(sp)
    80004142:	e8a2                	sd	s0,80(sp)
    80004144:	e4a6                	sd	s1,72(sp)
    80004146:	e0ca                	sd	s2,64(sp)
    80004148:	fc4e                	sd	s3,56(sp)
    8000414a:	f852                	sd	s4,48(sp)
    8000414c:	f456                	sd	s5,40(sp)
    8000414e:	f05a                	sd	s6,32(sp)
    80004150:	ec5e                	sd	s7,24(sp)
    80004152:	e862                	sd	s8,16(sp)
    80004154:	e466                	sd	s9,8(sp)
    80004156:	1080                	add	s0,sp,96
    80004158:	84aa                	mv	s1,a0
    8000415a:	8b2e                	mv	s6,a1
    8000415c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000415e:	00054703          	lbu	a4,0(a0)
    80004162:	02f00793          	li	a5,47
    80004166:	02f70263          	beq	a4,a5,8000418a <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000416a:	ffffe097          	auipc	ra,0xffffe
    8000416e:	8d8080e7          	jalr	-1832(ra) # 80001a42 <myproc>
    80004172:	15053503          	ld	a0,336(a0)
    80004176:	00000097          	auipc	ra,0x0
    8000417a:	9f6080e7          	jalr	-1546(ra) # 80003b6c <idup>
    8000417e:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004180:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004184:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004186:	4b85                	li	s7,1
    80004188:	a875                	j	80004244 <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    8000418a:	4585                	li	a1,1
    8000418c:	4505                	li	a0,1
    8000418e:	fffff097          	auipc	ra,0xfffff
    80004192:	6e8080e7          	jalr	1768(ra) # 80003876 <iget>
    80004196:	8a2a                	mv	s4,a0
    80004198:	b7e5                	j	80004180 <namex+0x42>
      iunlockput(ip);
    8000419a:	8552                	mv	a0,s4
    8000419c:	00000097          	auipc	ra,0x0
    800041a0:	c70080e7          	jalr	-912(ra) # 80003e0c <iunlockput>
      return 0;
    800041a4:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800041a6:	8552                	mv	a0,s4
    800041a8:	60e6                	ld	ra,88(sp)
    800041aa:	6446                	ld	s0,80(sp)
    800041ac:	64a6                	ld	s1,72(sp)
    800041ae:	6906                	ld	s2,64(sp)
    800041b0:	79e2                	ld	s3,56(sp)
    800041b2:	7a42                	ld	s4,48(sp)
    800041b4:	7aa2                	ld	s5,40(sp)
    800041b6:	7b02                	ld	s6,32(sp)
    800041b8:	6be2                	ld	s7,24(sp)
    800041ba:	6c42                	ld	s8,16(sp)
    800041bc:	6ca2                	ld	s9,8(sp)
    800041be:	6125                	add	sp,sp,96
    800041c0:	8082                	ret
      iunlock(ip);
    800041c2:	8552                	mv	a0,s4
    800041c4:	00000097          	auipc	ra,0x0
    800041c8:	aa8080e7          	jalr	-1368(ra) # 80003c6c <iunlock>
      return ip;
    800041cc:	bfe9                	j	800041a6 <namex+0x68>
      iunlockput(ip);
    800041ce:	8552                	mv	a0,s4
    800041d0:	00000097          	auipc	ra,0x0
    800041d4:	c3c080e7          	jalr	-964(ra) # 80003e0c <iunlockput>
      return 0;
    800041d8:	8a4e                	mv	s4,s3
    800041da:	b7f1                	j	800041a6 <namex+0x68>
  len = path - s;
    800041dc:	40998633          	sub	a2,s3,s1
    800041e0:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800041e4:	099c5863          	bge	s8,s9,80004274 <namex+0x136>
    memmove(name, s, DIRSIZ);
    800041e8:	4639                	li	a2,14
    800041ea:	85a6                	mv	a1,s1
    800041ec:	8556                	mv	a0,s5
    800041ee:	ffffd097          	auipc	ra,0xffffd
    800041f2:	c06080e7          	jalr	-1018(ra) # 80000df4 <memmove>
    800041f6:	84ce                	mv	s1,s3
  while(*path == '/')
    800041f8:	0004c783          	lbu	a5,0(s1)
    800041fc:	01279763          	bne	a5,s2,8000420a <namex+0xcc>
    path++;
    80004200:	0485                	add	s1,s1,1
  while(*path == '/')
    80004202:	0004c783          	lbu	a5,0(s1)
    80004206:	ff278de3          	beq	a5,s2,80004200 <namex+0xc2>
    ilock(ip);
    8000420a:	8552                	mv	a0,s4
    8000420c:	00000097          	auipc	ra,0x0
    80004210:	99e080e7          	jalr	-1634(ra) # 80003baa <ilock>
    if(ip->type != T_DIR){
    80004214:	044a1783          	lh	a5,68(s4)
    80004218:	f97791e3          	bne	a5,s7,8000419a <namex+0x5c>
    if(nameiparent && *path == '\0'){
    8000421c:	000b0563          	beqz	s6,80004226 <namex+0xe8>
    80004220:	0004c783          	lbu	a5,0(s1)
    80004224:	dfd9                	beqz	a5,800041c2 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004226:	4601                	li	a2,0
    80004228:	85d6                	mv	a1,s5
    8000422a:	8552                	mv	a0,s4
    8000422c:	00000097          	auipc	ra,0x0
    80004230:	e62080e7          	jalr	-414(ra) # 8000408e <dirlookup>
    80004234:	89aa                	mv	s3,a0
    80004236:	dd41                	beqz	a0,800041ce <namex+0x90>
    iunlockput(ip);
    80004238:	8552                	mv	a0,s4
    8000423a:	00000097          	auipc	ra,0x0
    8000423e:	bd2080e7          	jalr	-1070(ra) # 80003e0c <iunlockput>
    ip = next;
    80004242:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004244:	0004c783          	lbu	a5,0(s1)
    80004248:	01279763          	bne	a5,s2,80004256 <namex+0x118>
    path++;
    8000424c:	0485                	add	s1,s1,1
  while(*path == '/')
    8000424e:	0004c783          	lbu	a5,0(s1)
    80004252:	ff278de3          	beq	a5,s2,8000424c <namex+0x10e>
  if(*path == 0)
    80004256:	cb9d                	beqz	a5,8000428c <namex+0x14e>
  while(*path != '/' && *path != 0)
    80004258:	0004c783          	lbu	a5,0(s1)
    8000425c:	89a6                	mv	s3,s1
  len = path - s;
    8000425e:	4c81                	li	s9,0
    80004260:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80004262:	01278963          	beq	a5,s2,80004274 <namex+0x136>
    80004266:	dbbd                	beqz	a5,800041dc <namex+0x9e>
    path++;
    80004268:	0985                	add	s3,s3,1
  while(*path != '/' && *path != 0)
    8000426a:	0009c783          	lbu	a5,0(s3)
    8000426e:	ff279ce3          	bne	a5,s2,80004266 <namex+0x128>
    80004272:	b7ad                	j	800041dc <namex+0x9e>
    memmove(name, s, len);
    80004274:	2601                	sext.w	a2,a2
    80004276:	85a6                	mv	a1,s1
    80004278:	8556                	mv	a0,s5
    8000427a:	ffffd097          	auipc	ra,0xffffd
    8000427e:	b7a080e7          	jalr	-1158(ra) # 80000df4 <memmove>
    name[len] = 0;
    80004282:	9cd6                	add	s9,s9,s5
    80004284:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004288:	84ce                	mv	s1,s3
    8000428a:	b7bd                	j	800041f8 <namex+0xba>
  if(nameiparent){
    8000428c:	f00b0de3          	beqz	s6,800041a6 <namex+0x68>
    iput(ip);
    80004290:	8552                	mv	a0,s4
    80004292:	00000097          	auipc	ra,0x0
    80004296:	ad2080e7          	jalr	-1326(ra) # 80003d64 <iput>
    return 0;
    8000429a:	4a01                	li	s4,0
    8000429c:	b729                	j	800041a6 <namex+0x68>

000000008000429e <dirlink>:
{
    8000429e:	7139                	add	sp,sp,-64
    800042a0:	fc06                	sd	ra,56(sp)
    800042a2:	f822                	sd	s0,48(sp)
    800042a4:	f426                	sd	s1,40(sp)
    800042a6:	f04a                	sd	s2,32(sp)
    800042a8:	ec4e                	sd	s3,24(sp)
    800042aa:	e852                	sd	s4,16(sp)
    800042ac:	0080                	add	s0,sp,64
    800042ae:	892a                	mv	s2,a0
    800042b0:	8a2e                	mv	s4,a1
    800042b2:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800042b4:	4601                	li	a2,0
    800042b6:	00000097          	auipc	ra,0x0
    800042ba:	dd8080e7          	jalr	-552(ra) # 8000408e <dirlookup>
    800042be:	e93d                	bnez	a0,80004334 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042c0:	04c92483          	lw	s1,76(s2)
    800042c4:	c49d                	beqz	s1,800042f2 <dirlink+0x54>
    800042c6:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042c8:	4741                	li	a4,16
    800042ca:	86a6                	mv	a3,s1
    800042cc:	fc040613          	add	a2,s0,-64
    800042d0:	4581                	li	a1,0
    800042d2:	854a                	mv	a0,s2
    800042d4:	00000097          	auipc	ra,0x0
    800042d8:	b8a080e7          	jalr	-1142(ra) # 80003e5e <readi>
    800042dc:	47c1                	li	a5,16
    800042de:	06f51163          	bne	a0,a5,80004340 <dirlink+0xa2>
    if(de.inum == 0)
    800042e2:	fc045783          	lhu	a5,-64(s0)
    800042e6:	c791                	beqz	a5,800042f2 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042e8:	24c1                	addw	s1,s1,16
    800042ea:	04c92783          	lw	a5,76(s2)
    800042ee:	fcf4ede3          	bltu	s1,a5,800042c8 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800042f2:	4639                	li	a2,14
    800042f4:	85d2                	mv	a1,s4
    800042f6:	fc240513          	add	a0,s0,-62
    800042fa:	ffffd097          	auipc	ra,0xffffd
    800042fe:	baa080e7          	jalr	-1110(ra) # 80000ea4 <strncpy>
  de.inum = inum;
    80004302:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004306:	4741                	li	a4,16
    80004308:	86a6                	mv	a3,s1
    8000430a:	fc040613          	add	a2,s0,-64
    8000430e:	4581                	li	a1,0
    80004310:	854a                	mv	a0,s2
    80004312:	00000097          	auipc	ra,0x0
    80004316:	c44080e7          	jalr	-956(ra) # 80003f56 <writei>
    8000431a:	1541                	add	a0,a0,-16
    8000431c:	00a03533          	snez	a0,a0
    80004320:	40a00533          	neg	a0,a0
}
    80004324:	70e2                	ld	ra,56(sp)
    80004326:	7442                	ld	s0,48(sp)
    80004328:	74a2                	ld	s1,40(sp)
    8000432a:	7902                	ld	s2,32(sp)
    8000432c:	69e2                	ld	s3,24(sp)
    8000432e:	6a42                	ld	s4,16(sp)
    80004330:	6121                	add	sp,sp,64
    80004332:	8082                	ret
    iput(ip);
    80004334:	00000097          	auipc	ra,0x0
    80004338:	a30080e7          	jalr	-1488(ra) # 80003d64 <iput>
    return -1;
    8000433c:	557d                	li	a0,-1
    8000433e:	b7dd                	j	80004324 <dirlink+0x86>
      panic("dirlink read");
    80004340:	00004517          	auipc	a0,0x4
    80004344:	31850513          	add	a0,a0,792 # 80008658 <syscalls+0x1e0>
    80004348:	ffffc097          	auipc	ra,0xffffc
    8000434c:	1f4080e7          	jalr	500(ra) # 8000053c <panic>

0000000080004350 <namei>:

struct inode*
namei(char *path)
{
    80004350:	1101                	add	sp,sp,-32
    80004352:	ec06                	sd	ra,24(sp)
    80004354:	e822                	sd	s0,16(sp)
    80004356:	1000                	add	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004358:	fe040613          	add	a2,s0,-32
    8000435c:	4581                	li	a1,0
    8000435e:	00000097          	auipc	ra,0x0
    80004362:	de0080e7          	jalr	-544(ra) # 8000413e <namex>
}
    80004366:	60e2                	ld	ra,24(sp)
    80004368:	6442                	ld	s0,16(sp)
    8000436a:	6105                	add	sp,sp,32
    8000436c:	8082                	ret

000000008000436e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000436e:	1141                	add	sp,sp,-16
    80004370:	e406                	sd	ra,8(sp)
    80004372:	e022                	sd	s0,0(sp)
    80004374:	0800                	add	s0,sp,16
    80004376:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004378:	4585                	li	a1,1
    8000437a:	00000097          	auipc	ra,0x0
    8000437e:	dc4080e7          	jalr	-572(ra) # 8000413e <namex>
}
    80004382:	60a2                	ld	ra,8(sp)
    80004384:	6402                	ld	s0,0(sp)
    80004386:	0141                	add	sp,sp,16
    80004388:	8082                	ret

000000008000438a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000438a:	1101                	add	sp,sp,-32
    8000438c:	ec06                	sd	ra,24(sp)
    8000438e:	e822                	sd	s0,16(sp)
    80004390:	e426                	sd	s1,8(sp)
    80004392:	e04a                	sd	s2,0(sp)
    80004394:	1000                	add	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004396:	0023d917          	auipc	s2,0x23d
    8000439a:	faa90913          	add	s2,s2,-86 # 80241340 <log>
    8000439e:	01892583          	lw	a1,24(s2)
    800043a2:	02892503          	lw	a0,40(s2)
    800043a6:	fffff097          	auipc	ra,0xfffff
    800043aa:	ff4080e7          	jalr	-12(ra) # 8000339a <bread>
    800043ae:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800043b0:	02c92603          	lw	a2,44(s2)
    800043b4:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800043b6:	00c05f63          	blez	a2,800043d4 <write_head+0x4a>
    800043ba:	0023d717          	auipc	a4,0x23d
    800043be:	fb670713          	add	a4,a4,-74 # 80241370 <log+0x30>
    800043c2:	87aa                	mv	a5,a0
    800043c4:	060a                	sll	a2,a2,0x2
    800043c6:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    800043c8:	4314                	lw	a3,0(a4)
    800043ca:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    800043cc:	0711                	add	a4,a4,4
    800043ce:	0791                	add	a5,a5,4
    800043d0:	fec79ce3          	bne	a5,a2,800043c8 <write_head+0x3e>
  }
  bwrite(buf);
    800043d4:	8526                	mv	a0,s1
    800043d6:	fffff097          	auipc	ra,0xfffff
    800043da:	0b6080e7          	jalr	182(ra) # 8000348c <bwrite>
  brelse(buf);
    800043de:	8526                	mv	a0,s1
    800043e0:	fffff097          	auipc	ra,0xfffff
    800043e4:	0ea080e7          	jalr	234(ra) # 800034ca <brelse>
}
    800043e8:	60e2                	ld	ra,24(sp)
    800043ea:	6442                	ld	s0,16(sp)
    800043ec:	64a2                	ld	s1,8(sp)
    800043ee:	6902                	ld	s2,0(sp)
    800043f0:	6105                	add	sp,sp,32
    800043f2:	8082                	ret

00000000800043f4 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800043f4:	0023d797          	auipc	a5,0x23d
    800043f8:	f787a783          	lw	a5,-136(a5) # 8024136c <log+0x2c>
    800043fc:	0af05d63          	blez	a5,800044b6 <install_trans+0xc2>
{
    80004400:	7139                	add	sp,sp,-64
    80004402:	fc06                	sd	ra,56(sp)
    80004404:	f822                	sd	s0,48(sp)
    80004406:	f426                	sd	s1,40(sp)
    80004408:	f04a                	sd	s2,32(sp)
    8000440a:	ec4e                	sd	s3,24(sp)
    8000440c:	e852                	sd	s4,16(sp)
    8000440e:	e456                	sd	s5,8(sp)
    80004410:	e05a                	sd	s6,0(sp)
    80004412:	0080                	add	s0,sp,64
    80004414:	8b2a                	mv	s6,a0
    80004416:	0023da97          	auipc	s5,0x23d
    8000441a:	f5aa8a93          	add	s5,s5,-166 # 80241370 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000441e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004420:	0023d997          	auipc	s3,0x23d
    80004424:	f2098993          	add	s3,s3,-224 # 80241340 <log>
    80004428:	a00d                	j	8000444a <install_trans+0x56>
    brelse(lbuf);
    8000442a:	854a                	mv	a0,s2
    8000442c:	fffff097          	auipc	ra,0xfffff
    80004430:	09e080e7          	jalr	158(ra) # 800034ca <brelse>
    brelse(dbuf);
    80004434:	8526                	mv	a0,s1
    80004436:	fffff097          	auipc	ra,0xfffff
    8000443a:	094080e7          	jalr	148(ra) # 800034ca <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000443e:	2a05                	addw	s4,s4,1
    80004440:	0a91                	add	s5,s5,4
    80004442:	02c9a783          	lw	a5,44(s3)
    80004446:	04fa5e63          	bge	s4,a5,800044a2 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000444a:	0189a583          	lw	a1,24(s3)
    8000444e:	014585bb          	addw	a1,a1,s4
    80004452:	2585                	addw	a1,a1,1
    80004454:	0289a503          	lw	a0,40(s3)
    80004458:	fffff097          	auipc	ra,0xfffff
    8000445c:	f42080e7          	jalr	-190(ra) # 8000339a <bread>
    80004460:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004462:	000aa583          	lw	a1,0(s5)
    80004466:	0289a503          	lw	a0,40(s3)
    8000446a:	fffff097          	auipc	ra,0xfffff
    8000446e:	f30080e7          	jalr	-208(ra) # 8000339a <bread>
    80004472:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004474:	40000613          	li	a2,1024
    80004478:	05890593          	add	a1,s2,88
    8000447c:	05850513          	add	a0,a0,88
    80004480:	ffffd097          	auipc	ra,0xffffd
    80004484:	974080e7          	jalr	-1676(ra) # 80000df4 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004488:	8526                	mv	a0,s1
    8000448a:	fffff097          	auipc	ra,0xfffff
    8000448e:	002080e7          	jalr	2(ra) # 8000348c <bwrite>
    if(recovering == 0)
    80004492:	f80b1ce3          	bnez	s6,8000442a <install_trans+0x36>
      bunpin(dbuf);
    80004496:	8526                	mv	a0,s1
    80004498:	fffff097          	auipc	ra,0xfffff
    8000449c:	10a080e7          	jalr	266(ra) # 800035a2 <bunpin>
    800044a0:	b769                	j	8000442a <install_trans+0x36>
}
    800044a2:	70e2                	ld	ra,56(sp)
    800044a4:	7442                	ld	s0,48(sp)
    800044a6:	74a2                	ld	s1,40(sp)
    800044a8:	7902                	ld	s2,32(sp)
    800044aa:	69e2                	ld	s3,24(sp)
    800044ac:	6a42                	ld	s4,16(sp)
    800044ae:	6aa2                	ld	s5,8(sp)
    800044b0:	6b02                	ld	s6,0(sp)
    800044b2:	6121                	add	sp,sp,64
    800044b4:	8082                	ret
    800044b6:	8082                	ret

00000000800044b8 <initlog>:
{
    800044b8:	7179                	add	sp,sp,-48
    800044ba:	f406                	sd	ra,40(sp)
    800044bc:	f022                	sd	s0,32(sp)
    800044be:	ec26                	sd	s1,24(sp)
    800044c0:	e84a                	sd	s2,16(sp)
    800044c2:	e44e                	sd	s3,8(sp)
    800044c4:	1800                	add	s0,sp,48
    800044c6:	892a                	mv	s2,a0
    800044c8:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800044ca:	0023d497          	auipc	s1,0x23d
    800044ce:	e7648493          	add	s1,s1,-394 # 80241340 <log>
    800044d2:	00004597          	auipc	a1,0x4
    800044d6:	19658593          	add	a1,a1,406 # 80008668 <syscalls+0x1f0>
    800044da:	8526                	mv	a0,s1
    800044dc:	ffffc097          	auipc	ra,0xffffc
    800044e0:	730080e7          	jalr	1840(ra) # 80000c0c <initlock>
  log.start = sb->logstart;
    800044e4:	0149a583          	lw	a1,20(s3)
    800044e8:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800044ea:	0109a783          	lw	a5,16(s3)
    800044ee:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800044f0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800044f4:	854a                	mv	a0,s2
    800044f6:	fffff097          	auipc	ra,0xfffff
    800044fa:	ea4080e7          	jalr	-348(ra) # 8000339a <bread>
  log.lh.n = lh->n;
    800044fe:	4d30                	lw	a2,88(a0)
    80004500:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004502:	00c05f63          	blez	a2,80004520 <initlog+0x68>
    80004506:	87aa                	mv	a5,a0
    80004508:	0023d717          	auipc	a4,0x23d
    8000450c:	e6870713          	add	a4,a4,-408 # 80241370 <log+0x30>
    80004510:	060a                	sll	a2,a2,0x2
    80004512:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80004514:	4ff4                	lw	a3,92(a5)
    80004516:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004518:	0791                	add	a5,a5,4
    8000451a:	0711                	add	a4,a4,4
    8000451c:	fec79ce3          	bne	a5,a2,80004514 <initlog+0x5c>
  brelse(buf);
    80004520:	fffff097          	auipc	ra,0xfffff
    80004524:	faa080e7          	jalr	-86(ra) # 800034ca <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004528:	4505                	li	a0,1
    8000452a:	00000097          	auipc	ra,0x0
    8000452e:	eca080e7          	jalr	-310(ra) # 800043f4 <install_trans>
  log.lh.n = 0;
    80004532:	0023d797          	auipc	a5,0x23d
    80004536:	e207ad23          	sw	zero,-454(a5) # 8024136c <log+0x2c>
  write_head(); // clear the log
    8000453a:	00000097          	auipc	ra,0x0
    8000453e:	e50080e7          	jalr	-432(ra) # 8000438a <write_head>
}
    80004542:	70a2                	ld	ra,40(sp)
    80004544:	7402                	ld	s0,32(sp)
    80004546:	64e2                	ld	s1,24(sp)
    80004548:	6942                	ld	s2,16(sp)
    8000454a:	69a2                	ld	s3,8(sp)
    8000454c:	6145                	add	sp,sp,48
    8000454e:	8082                	ret

0000000080004550 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004550:	1101                	add	sp,sp,-32
    80004552:	ec06                	sd	ra,24(sp)
    80004554:	e822                	sd	s0,16(sp)
    80004556:	e426                	sd	s1,8(sp)
    80004558:	e04a                	sd	s2,0(sp)
    8000455a:	1000                	add	s0,sp,32
  acquire(&log.lock);
    8000455c:	0023d517          	auipc	a0,0x23d
    80004560:	de450513          	add	a0,a0,-540 # 80241340 <log>
    80004564:	ffffc097          	auipc	ra,0xffffc
    80004568:	738080e7          	jalr	1848(ra) # 80000c9c <acquire>
  while(1){
    if(log.committing){
    8000456c:	0023d497          	auipc	s1,0x23d
    80004570:	dd448493          	add	s1,s1,-556 # 80241340 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004574:	4979                	li	s2,30
    80004576:	a039                	j	80004584 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004578:	85a6                	mv	a1,s1
    8000457a:	8526                	mv	a0,s1
    8000457c:	ffffe097          	auipc	ra,0xffffe
    80004580:	d7a080e7          	jalr	-646(ra) # 800022f6 <sleep>
    if(log.committing){
    80004584:	50dc                	lw	a5,36(s1)
    80004586:	fbed                	bnez	a5,80004578 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004588:	5098                	lw	a4,32(s1)
    8000458a:	2705                	addw	a4,a4,1
    8000458c:	0027179b          	sllw	a5,a4,0x2
    80004590:	9fb9                	addw	a5,a5,a4
    80004592:	0017979b          	sllw	a5,a5,0x1
    80004596:	54d4                	lw	a3,44(s1)
    80004598:	9fb5                	addw	a5,a5,a3
    8000459a:	00f95963          	bge	s2,a5,800045ac <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000459e:	85a6                	mv	a1,s1
    800045a0:	8526                	mv	a0,s1
    800045a2:	ffffe097          	auipc	ra,0xffffe
    800045a6:	d54080e7          	jalr	-684(ra) # 800022f6 <sleep>
    800045aa:	bfe9                	j	80004584 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800045ac:	0023d517          	auipc	a0,0x23d
    800045b0:	d9450513          	add	a0,a0,-620 # 80241340 <log>
    800045b4:	d118                	sw	a4,32(a0)
      release(&log.lock);
    800045b6:	ffffc097          	auipc	ra,0xffffc
    800045ba:	79a080e7          	jalr	1946(ra) # 80000d50 <release>
      break;
    }
  }
}
    800045be:	60e2                	ld	ra,24(sp)
    800045c0:	6442                	ld	s0,16(sp)
    800045c2:	64a2                	ld	s1,8(sp)
    800045c4:	6902                	ld	s2,0(sp)
    800045c6:	6105                	add	sp,sp,32
    800045c8:	8082                	ret

00000000800045ca <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800045ca:	7139                	add	sp,sp,-64
    800045cc:	fc06                	sd	ra,56(sp)
    800045ce:	f822                	sd	s0,48(sp)
    800045d0:	f426                	sd	s1,40(sp)
    800045d2:	f04a                	sd	s2,32(sp)
    800045d4:	ec4e                	sd	s3,24(sp)
    800045d6:	e852                	sd	s4,16(sp)
    800045d8:	e456                	sd	s5,8(sp)
    800045da:	0080                	add	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800045dc:	0023d497          	auipc	s1,0x23d
    800045e0:	d6448493          	add	s1,s1,-668 # 80241340 <log>
    800045e4:	8526                	mv	a0,s1
    800045e6:	ffffc097          	auipc	ra,0xffffc
    800045ea:	6b6080e7          	jalr	1718(ra) # 80000c9c <acquire>
  log.outstanding -= 1;
    800045ee:	509c                	lw	a5,32(s1)
    800045f0:	37fd                	addw	a5,a5,-1
    800045f2:	0007891b          	sext.w	s2,a5
    800045f6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800045f8:	50dc                	lw	a5,36(s1)
    800045fa:	e7b9                	bnez	a5,80004648 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800045fc:	04091e63          	bnez	s2,80004658 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004600:	0023d497          	auipc	s1,0x23d
    80004604:	d4048493          	add	s1,s1,-704 # 80241340 <log>
    80004608:	4785                	li	a5,1
    8000460a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000460c:	8526                	mv	a0,s1
    8000460e:	ffffc097          	auipc	ra,0xffffc
    80004612:	742080e7          	jalr	1858(ra) # 80000d50 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004616:	54dc                	lw	a5,44(s1)
    80004618:	06f04763          	bgtz	a5,80004686 <end_op+0xbc>
    acquire(&log.lock);
    8000461c:	0023d497          	auipc	s1,0x23d
    80004620:	d2448493          	add	s1,s1,-732 # 80241340 <log>
    80004624:	8526                	mv	a0,s1
    80004626:	ffffc097          	auipc	ra,0xffffc
    8000462a:	676080e7          	jalr	1654(ra) # 80000c9c <acquire>
    log.committing = 0;
    8000462e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004632:	8526                	mv	a0,s1
    80004634:	ffffe097          	auipc	ra,0xffffe
    80004638:	d26080e7          	jalr	-730(ra) # 8000235a <wakeup>
    release(&log.lock);
    8000463c:	8526                	mv	a0,s1
    8000463e:	ffffc097          	auipc	ra,0xffffc
    80004642:	712080e7          	jalr	1810(ra) # 80000d50 <release>
}
    80004646:	a03d                	j	80004674 <end_op+0xaa>
    panic("log.committing");
    80004648:	00004517          	auipc	a0,0x4
    8000464c:	02850513          	add	a0,a0,40 # 80008670 <syscalls+0x1f8>
    80004650:	ffffc097          	auipc	ra,0xffffc
    80004654:	eec080e7          	jalr	-276(ra) # 8000053c <panic>
    wakeup(&log);
    80004658:	0023d497          	auipc	s1,0x23d
    8000465c:	ce848493          	add	s1,s1,-792 # 80241340 <log>
    80004660:	8526                	mv	a0,s1
    80004662:	ffffe097          	auipc	ra,0xffffe
    80004666:	cf8080e7          	jalr	-776(ra) # 8000235a <wakeup>
  release(&log.lock);
    8000466a:	8526                	mv	a0,s1
    8000466c:	ffffc097          	auipc	ra,0xffffc
    80004670:	6e4080e7          	jalr	1764(ra) # 80000d50 <release>
}
    80004674:	70e2                	ld	ra,56(sp)
    80004676:	7442                	ld	s0,48(sp)
    80004678:	74a2                	ld	s1,40(sp)
    8000467a:	7902                	ld	s2,32(sp)
    8000467c:	69e2                	ld	s3,24(sp)
    8000467e:	6a42                	ld	s4,16(sp)
    80004680:	6aa2                	ld	s5,8(sp)
    80004682:	6121                	add	sp,sp,64
    80004684:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004686:	0023da97          	auipc	s5,0x23d
    8000468a:	ceaa8a93          	add	s5,s5,-790 # 80241370 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000468e:	0023da17          	auipc	s4,0x23d
    80004692:	cb2a0a13          	add	s4,s4,-846 # 80241340 <log>
    80004696:	018a2583          	lw	a1,24(s4)
    8000469a:	012585bb          	addw	a1,a1,s2
    8000469e:	2585                	addw	a1,a1,1
    800046a0:	028a2503          	lw	a0,40(s4)
    800046a4:	fffff097          	auipc	ra,0xfffff
    800046a8:	cf6080e7          	jalr	-778(ra) # 8000339a <bread>
    800046ac:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800046ae:	000aa583          	lw	a1,0(s5)
    800046b2:	028a2503          	lw	a0,40(s4)
    800046b6:	fffff097          	auipc	ra,0xfffff
    800046ba:	ce4080e7          	jalr	-796(ra) # 8000339a <bread>
    800046be:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800046c0:	40000613          	li	a2,1024
    800046c4:	05850593          	add	a1,a0,88
    800046c8:	05848513          	add	a0,s1,88
    800046cc:	ffffc097          	auipc	ra,0xffffc
    800046d0:	728080e7          	jalr	1832(ra) # 80000df4 <memmove>
    bwrite(to);  // write the log
    800046d4:	8526                	mv	a0,s1
    800046d6:	fffff097          	auipc	ra,0xfffff
    800046da:	db6080e7          	jalr	-586(ra) # 8000348c <bwrite>
    brelse(from);
    800046de:	854e                	mv	a0,s3
    800046e0:	fffff097          	auipc	ra,0xfffff
    800046e4:	dea080e7          	jalr	-534(ra) # 800034ca <brelse>
    brelse(to);
    800046e8:	8526                	mv	a0,s1
    800046ea:	fffff097          	auipc	ra,0xfffff
    800046ee:	de0080e7          	jalr	-544(ra) # 800034ca <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046f2:	2905                	addw	s2,s2,1
    800046f4:	0a91                	add	s5,s5,4
    800046f6:	02ca2783          	lw	a5,44(s4)
    800046fa:	f8f94ee3          	blt	s2,a5,80004696 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800046fe:	00000097          	auipc	ra,0x0
    80004702:	c8c080e7          	jalr	-884(ra) # 8000438a <write_head>
    install_trans(0); // Now install writes to home locations
    80004706:	4501                	li	a0,0
    80004708:	00000097          	auipc	ra,0x0
    8000470c:	cec080e7          	jalr	-788(ra) # 800043f4 <install_trans>
    log.lh.n = 0;
    80004710:	0023d797          	auipc	a5,0x23d
    80004714:	c407ae23          	sw	zero,-932(a5) # 8024136c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004718:	00000097          	auipc	ra,0x0
    8000471c:	c72080e7          	jalr	-910(ra) # 8000438a <write_head>
    80004720:	bdf5                	j	8000461c <end_op+0x52>

0000000080004722 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004722:	1101                	add	sp,sp,-32
    80004724:	ec06                	sd	ra,24(sp)
    80004726:	e822                	sd	s0,16(sp)
    80004728:	e426                	sd	s1,8(sp)
    8000472a:	e04a                	sd	s2,0(sp)
    8000472c:	1000                	add	s0,sp,32
    8000472e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004730:	0023d917          	auipc	s2,0x23d
    80004734:	c1090913          	add	s2,s2,-1008 # 80241340 <log>
    80004738:	854a                	mv	a0,s2
    8000473a:	ffffc097          	auipc	ra,0xffffc
    8000473e:	562080e7          	jalr	1378(ra) # 80000c9c <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004742:	02c92603          	lw	a2,44(s2)
    80004746:	47f5                	li	a5,29
    80004748:	06c7c563          	blt	a5,a2,800047b2 <log_write+0x90>
    8000474c:	0023d797          	auipc	a5,0x23d
    80004750:	c107a783          	lw	a5,-1008(a5) # 8024135c <log+0x1c>
    80004754:	37fd                	addw	a5,a5,-1
    80004756:	04f65e63          	bge	a2,a5,800047b2 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000475a:	0023d797          	auipc	a5,0x23d
    8000475e:	c067a783          	lw	a5,-1018(a5) # 80241360 <log+0x20>
    80004762:	06f05063          	blez	a5,800047c2 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004766:	4781                	li	a5,0
    80004768:	06c05563          	blez	a2,800047d2 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000476c:	44cc                	lw	a1,12(s1)
    8000476e:	0023d717          	auipc	a4,0x23d
    80004772:	c0270713          	add	a4,a4,-1022 # 80241370 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004776:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004778:	4314                	lw	a3,0(a4)
    8000477a:	04b68c63          	beq	a3,a1,800047d2 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000477e:	2785                	addw	a5,a5,1
    80004780:	0711                	add	a4,a4,4
    80004782:	fef61be3          	bne	a2,a5,80004778 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004786:	0621                	add	a2,a2,8
    80004788:	060a                	sll	a2,a2,0x2
    8000478a:	0023d797          	auipc	a5,0x23d
    8000478e:	bb678793          	add	a5,a5,-1098 # 80241340 <log>
    80004792:	97b2                	add	a5,a5,a2
    80004794:	44d8                	lw	a4,12(s1)
    80004796:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004798:	8526                	mv	a0,s1
    8000479a:	fffff097          	auipc	ra,0xfffff
    8000479e:	dcc080e7          	jalr	-564(ra) # 80003566 <bpin>
    log.lh.n++;
    800047a2:	0023d717          	auipc	a4,0x23d
    800047a6:	b9e70713          	add	a4,a4,-1122 # 80241340 <log>
    800047aa:	575c                	lw	a5,44(a4)
    800047ac:	2785                	addw	a5,a5,1
    800047ae:	d75c                	sw	a5,44(a4)
    800047b0:	a82d                	j	800047ea <log_write+0xc8>
    panic("too big a transaction");
    800047b2:	00004517          	auipc	a0,0x4
    800047b6:	ece50513          	add	a0,a0,-306 # 80008680 <syscalls+0x208>
    800047ba:	ffffc097          	auipc	ra,0xffffc
    800047be:	d82080e7          	jalr	-638(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    800047c2:	00004517          	auipc	a0,0x4
    800047c6:	ed650513          	add	a0,a0,-298 # 80008698 <syscalls+0x220>
    800047ca:	ffffc097          	auipc	ra,0xffffc
    800047ce:	d72080e7          	jalr	-654(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    800047d2:	00878693          	add	a3,a5,8
    800047d6:	068a                	sll	a3,a3,0x2
    800047d8:	0023d717          	auipc	a4,0x23d
    800047dc:	b6870713          	add	a4,a4,-1176 # 80241340 <log>
    800047e0:	9736                	add	a4,a4,a3
    800047e2:	44d4                	lw	a3,12(s1)
    800047e4:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800047e6:	faf609e3          	beq	a2,a5,80004798 <log_write+0x76>
  }
  release(&log.lock);
    800047ea:	0023d517          	auipc	a0,0x23d
    800047ee:	b5650513          	add	a0,a0,-1194 # 80241340 <log>
    800047f2:	ffffc097          	auipc	ra,0xffffc
    800047f6:	55e080e7          	jalr	1374(ra) # 80000d50 <release>
}
    800047fa:	60e2                	ld	ra,24(sp)
    800047fc:	6442                	ld	s0,16(sp)
    800047fe:	64a2                	ld	s1,8(sp)
    80004800:	6902                	ld	s2,0(sp)
    80004802:	6105                	add	sp,sp,32
    80004804:	8082                	ret

0000000080004806 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004806:	1101                	add	sp,sp,-32
    80004808:	ec06                	sd	ra,24(sp)
    8000480a:	e822                	sd	s0,16(sp)
    8000480c:	e426                	sd	s1,8(sp)
    8000480e:	e04a                	sd	s2,0(sp)
    80004810:	1000                	add	s0,sp,32
    80004812:	84aa                	mv	s1,a0
    80004814:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004816:	00004597          	auipc	a1,0x4
    8000481a:	ea258593          	add	a1,a1,-350 # 800086b8 <syscalls+0x240>
    8000481e:	0521                	add	a0,a0,8
    80004820:	ffffc097          	auipc	ra,0xffffc
    80004824:	3ec080e7          	jalr	1004(ra) # 80000c0c <initlock>
  lk->name = name;
    80004828:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000482c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004830:	0204a423          	sw	zero,40(s1)
}
    80004834:	60e2                	ld	ra,24(sp)
    80004836:	6442                	ld	s0,16(sp)
    80004838:	64a2                	ld	s1,8(sp)
    8000483a:	6902                	ld	s2,0(sp)
    8000483c:	6105                	add	sp,sp,32
    8000483e:	8082                	ret

0000000080004840 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004840:	1101                	add	sp,sp,-32
    80004842:	ec06                	sd	ra,24(sp)
    80004844:	e822                	sd	s0,16(sp)
    80004846:	e426                	sd	s1,8(sp)
    80004848:	e04a                	sd	s2,0(sp)
    8000484a:	1000                	add	s0,sp,32
    8000484c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000484e:	00850913          	add	s2,a0,8
    80004852:	854a                	mv	a0,s2
    80004854:	ffffc097          	auipc	ra,0xffffc
    80004858:	448080e7          	jalr	1096(ra) # 80000c9c <acquire>
  while (lk->locked) {
    8000485c:	409c                	lw	a5,0(s1)
    8000485e:	cb89                	beqz	a5,80004870 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004860:	85ca                	mv	a1,s2
    80004862:	8526                	mv	a0,s1
    80004864:	ffffe097          	auipc	ra,0xffffe
    80004868:	a92080e7          	jalr	-1390(ra) # 800022f6 <sleep>
  while (lk->locked) {
    8000486c:	409c                	lw	a5,0(s1)
    8000486e:	fbed                	bnez	a5,80004860 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004870:	4785                	li	a5,1
    80004872:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004874:	ffffd097          	auipc	ra,0xffffd
    80004878:	1ce080e7          	jalr	462(ra) # 80001a42 <myproc>
    8000487c:	591c                	lw	a5,48(a0)
    8000487e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004880:	854a                	mv	a0,s2
    80004882:	ffffc097          	auipc	ra,0xffffc
    80004886:	4ce080e7          	jalr	1230(ra) # 80000d50 <release>
}
    8000488a:	60e2                	ld	ra,24(sp)
    8000488c:	6442                	ld	s0,16(sp)
    8000488e:	64a2                	ld	s1,8(sp)
    80004890:	6902                	ld	s2,0(sp)
    80004892:	6105                	add	sp,sp,32
    80004894:	8082                	ret

0000000080004896 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004896:	1101                	add	sp,sp,-32
    80004898:	ec06                	sd	ra,24(sp)
    8000489a:	e822                	sd	s0,16(sp)
    8000489c:	e426                	sd	s1,8(sp)
    8000489e:	e04a                	sd	s2,0(sp)
    800048a0:	1000                	add	s0,sp,32
    800048a2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048a4:	00850913          	add	s2,a0,8
    800048a8:	854a                	mv	a0,s2
    800048aa:	ffffc097          	auipc	ra,0xffffc
    800048ae:	3f2080e7          	jalr	1010(ra) # 80000c9c <acquire>
  lk->locked = 0;
    800048b2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048b6:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800048ba:	8526                	mv	a0,s1
    800048bc:	ffffe097          	auipc	ra,0xffffe
    800048c0:	a9e080e7          	jalr	-1378(ra) # 8000235a <wakeup>
  release(&lk->lk);
    800048c4:	854a                	mv	a0,s2
    800048c6:	ffffc097          	auipc	ra,0xffffc
    800048ca:	48a080e7          	jalr	1162(ra) # 80000d50 <release>
}
    800048ce:	60e2                	ld	ra,24(sp)
    800048d0:	6442                	ld	s0,16(sp)
    800048d2:	64a2                	ld	s1,8(sp)
    800048d4:	6902                	ld	s2,0(sp)
    800048d6:	6105                	add	sp,sp,32
    800048d8:	8082                	ret

00000000800048da <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800048da:	7179                	add	sp,sp,-48
    800048dc:	f406                	sd	ra,40(sp)
    800048de:	f022                	sd	s0,32(sp)
    800048e0:	ec26                	sd	s1,24(sp)
    800048e2:	e84a                	sd	s2,16(sp)
    800048e4:	e44e                	sd	s3,8(sp)
    800048e6:	1800                	add	s0,sp,48
    800048e8:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800048ea:	00850913          	add	s2,a0,8
    800048ee:	854a                	mv	a0,s2
    800048f0:	ffffc097          	auipc	ra,0xffffc
    800048f4:	3ac080e7          	jalr	940(ra) # 80000c9c <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800048f8:	409c                	lw	a5,0(s1)
    800048fa:	ef99                	bnez	a5,80004918 <holdingsleep+0x3e>
    800048fc:	4481                	li	s1,0
  release(&lk->lk);
    800048fe:	854a                	mv	a0,s2
    80004900:	ffffc097          	auipc	ra,0xffffc
    80004904:	450080e7          	jalr	1104(ra) # 80000d50 <release>
  return r;
}
    80004908:	8526                	mv	a0,s1
    8000490a:	70a2                	ld	ra,40(sp)
    8000490c:	7402                	ld	s0,32(sp)
    8000490e:	64e2                	ld	s1,24(sp)
    80004910:	6942                	ld	s2,16(sp)
    80004912:	69a2                	ld	s3,8(sp)
    80004914:	6145                	add	sp,sp,48
    80004916:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004918:	0284a983          	lw	s3,40(s1)
    8000491c:	ffffd097          	auipc	ra,0xffffd
    80004920:	126080e7          	jalr	294(ra) # 80001a42 <myproc>
    80004924:	5904                	lw	s1,48(a0)
    80004926:	413484b3          	sub	s1,s1,s3
    8000492a:	0014b493          	seqz	s1,s1
    8000492e:	bfc1                	j	800048fe <holdingsleep+0x24>

0000000080004930 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004930:	1141                	add	sp,sp,-16
    80004932:	e406                	sd	ra,8(sp)
    80004934:	e022                	sd	s0,0(sp)
    80004936:	0800                	add	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004938:	00004597          	auipc	a1,0x4
    8000493c:	d9058593          	add	a1,a1,-624 # 800086c8 <syscalls+0x250>
    80004940:	0023d517          	auipc	a0,0x23d
    80004944:	b4850513          	add	a0,a0,-1208 # 80241488 <ftable>
    80004948:	ffffc097          	auipc	ra,0xffffc
    8000494c:	2c4080e7          	jalr	708(ra) # 80000c0c <initlock>
}
    80004950:	60a2                	ld	ra,8(sp)
    80004952:	6402                	ld	s0,0(sp)
    80004954:	0141                	add	sp,sp,16
    80004956:	8082                	ret

0000000080004958 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004958:	1101                	add	sp,sp,-32
    8000495a:	ec06                	sd	ra,24(sp)
    8000495c:	e822                	sd	s0,16(sp)
    8000495e:	e426                	sd	s1,8(sp)
    80004960:	1000                	add	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004962:	0023d517          	auipc	a0,0x23d
    80004966:	b2650513          	add	a0,a0,-1242 # 80241488 <ftable>
    8000496a:	ffffc097          	auipc	ra,0xffffc
    8000496e:	332080e7          	jalr	818(ra) # 80000c9c <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004972:	0023d497          	auipc	s1,0x23d
    80004976:	b2e48493          	add	s1,s1,-1234 # 802414a0 <ftable+0x18>
    8000497a:	0023e717          	auipc	a4,0x23e
    8000497e:	ac670713          	add	a4,a4,-1338 # 80242440 <disk>
    if(f->ref == 0){
    80004982:	40dc                	lw	a5,4(s1)
    80004984:	cf99                	beqz	a5,800049a2 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004986:	02848493          	add	s1,s1,40
    8000498a:	fee49ce3          	bne	s1,a4,80004982 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000498e:	0023d517          	auipc	a0,0x23d
    80004992:	afa50513          	add	a0,a0,-1286 # 80241488 <ftable>
    80004996:	ffffc097          	auipc	ra,0xffffc
    8000499a:	3ba080e7          	jalr	954(ra) # 80000d50 <release>
  return 0;
    8000499e:	4481                	li	s1,0
    800049a0:	a819                	j	800049b6 <filealloc+0x5e>
      f->ref = 1;
    800049a2:	4785                	li	a5,1
    800049a4:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800049a6:	0023d517          	auipc	a0,0x23d
    800049aa:	ae250513          	add	a0,a0,-1310 # 80241488 <ftable>
    800049ae:	ffffc097          	auipc	ra,0xffffc
    800049b2:	3a2080e7          	jalr	930(ra) # 80000d50 <release>
}
    800049b6:	8526                	mv	a0,s1
    800049b8:	60e2                	ld	ra,24(sp)
    800049ba:	6442                	ld	s0,16(sp)
    800049bc:	64a2                	ld	s1,8(sp)
    800049be:	6105                	add	sp,sp,32
    800049c0:	8082                	ret

00000000800049c2 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800049c2:	1101                	add	sp,sp,-32
    800049c4:	ec06                	sd	ra,24(sp)
    800049c6:	e822                	sd	s0,16(sp)
    800049c8:	e426                	sd	s1,8(sp)
    800049ca:	1000                	add	s0,sp,32
    800049cc:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800049ce:	0023d517          	auipc	a0,0x23d
    800049d2:	aba50513          	add	a0,a0,-1350 # 80241488 <ftable>
    800049d6:	ffffc097          	auipc	ra,0xffffc
    800049da:	2c6080e7          	jalr	710(ra) # 80000c9c <acquire>
  if(f->ref < 1)
    800049de:	40dc                	lw	a5,4(s1)
    800049e0:	02f05263          	blez	a5,80004a04 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800049e4:	2785                	addw	a5,a5,1
    800049e6:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800049e8:	0023d517          	auipc	a0,0x23d
    800049ec:	aa050513          	add	a0,a0,-1376 # 80241488 <ftable>
    800049f0:	ffffc097          	auipc	ra,0xffffc
    800049f4:	360080e7          	jalr	864(ra) # 80000d50 <release>
  return f;
}
    800049f8:	8526                	mv	a0,s1
    800049fa:	60e2                	ld	ra,24(sp)
    800049fc:	6442                	ld	s0,16(sp)
    800049fe:	64a2                	ld	s1,8(sp)
    80004a00:	6105                	add	sp,sp,32
    80004a02:	8082                	ret
    panic("filedup");
    80004a04:	00004517          	auipc	a0,0x4
    80004a08:	ccc50513          	add	a0,a0,-820 # 800086d0 <syscalls+0x258>
    80004a0c:	ffffc097          	auipc	ra,0xffffc
    80004a10:	b30080e7          	jalr	-1232(ra) # 8000053c <panic>

0000000080004a14 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004a14:	7139                	add	sp,sp,-64
    80004a16:	fc06                	sd	ra,56(sp)
    80004a18:	f822                	sd	s0,48(sp)
    80004a1a:	f426                	sd	s1,40(sp)
    80004a1c:	f04a                	sd	s2,32(sp)
    80004a1e:	ec4e                	sd	s3,24(sp)
    80004a20:	e852                	sd	s4,16(sp)
    80004a22:	e456                	sd	s5,8(sp)
    80004a24:	0080                	add	s0,sp,64
    80004a26:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004a28:	0023d517          	auipc	a0,0x23d
    80004a2c:	a6050513          	add	a0,a0,-1440 # 80241488 <ftable>
    80004a30:	ffffc097          	auipc	ra,0xffffc
    80004a34:	26c080e7          	jalr	620(ra) # 80000c9c <acquire>
  if(f->ref < 1)
    80004a38:	40dc                	lw	a5,4(s1)
    80004a3a:	06f05163          	blez	a5,80004a9c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004a3e:	37fd                	addw	a5,a5,-1
    80004a40:	0007871b          	sext.w	a4,a5
    80004a44:	c0dc                	sw	a5,4(s1)
    80004a46:	06e04363          	bgtz	a4,80004aac <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004a4a:	0004a903          	lw	s2,0(s1)
    80004a4e:	0094ca83          	lbu	s5,9(s1)
    80004a52:	0104ba03          	ld	s4,16(s1)
    80004a56:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004a5a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004a5e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004a62:	0023d517          	auipc	a0,0x23d
    80004a66:	a2650513          	add	a0,a0,-1498 # 80241488 <ftable>
    80004a6a:	ffffc097          	auipc	ra,0xffffc
    80004a6e:	2e6080e7          	jalr	742(ra) # 80000d50 <release>

  if(ff.type == FD_PIPE){
    80004a72:	4785                	li	a5,1
    80004a74:	04f90d63          	beq	s2,a5,80004ace <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004a78:	3979                	addw	s2,s2,-2
    80004a7a:	4785                	li	a5,1
    80004a7c:	0527e063          	bltu	a5,s2,80004abc <fileclose+0xa8>
    begin_op();
    80004a80:	00000097          	auipc	ra,0x0
    80004a84:	ad0080e7          	jalr	-1328(ra) # 80004550 <begin_op>
    iput(ff.ip);
    80004a88:	854e                	mv	a0,s3
    80004a8a:	fffff097          	auipc	ra,0xfffff
    80004a8e:	2da080e7          	jalr	730(ra) # 80003d64 <iput>
    end_op();
    80004a92:	00000097          	auipc	ra,0x0
    80004a96:	b38080e7          	jalr	-1224(ra) # 800045ca <end_op>
    80004a9a:	a00d                	j	80004abc <fileclose+0xa8>
    panic("fileclose");
    80004a9c:	00004517          	auipc	a0,0x4
    80004aa0:	c3c50513          	add	a0,a0,-964 # 800086d8 <syscalls+0x260>
    80004aa4:	ffffc097          	auipc	ra,0xffffc
    80004aa8:	a98080e7          	jalr	-1384(ra) # 8000053c <panic>
    release(&ftable.lock);
    80004aac:	0023d517          	auipc	a0,0x23d
    80004ab0:	9dc50513          	add	a0,a0,-1572 # 80241488 <ftable>
    80004ab4:	ffffc097          	auipc	ra,0xffffc
    80004ab8:	29c080e7          	jalr	668(ra) # 80000d50 <release>
  }
}
    80004abc:	70e2                	ld	ra,56(sp)
    80004abe:	7442                	ld	s0,48(sp)
    80004ac0:	74a2                	ld	s1,40(sp)
    80004ac2:	7902                	ld	s2,32(sp)
    80004ac4:	69e2                	ld	s3,24(sp)
    80004ac6:	6a42                	ld	s4,16(sp)
    80004ac8:	6aa2                	ld	s5,8(sp)
    80004aca:	6121                	add	sp,sp,64
    80004acc:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004ace:	85d6                	mv	a1,s5
    80004ad0:	8552                	mv	a0,s4
    80004ad2:	00000097          	auipc	ra,0x0
    80004ad6:	348080e7          	jalr	840(ra) # 80004e1a <pipeclose>
    80004ada:	b7cd                	j	80004abc <fileclose+0xa8>

0000000080004adc <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004adc:	715d                	add	sp,sp,-80
    80004ade:	e486                	sd	ra,72(sp)
    80004ae0:	e0a2                	sd	s0,64(sp)
    80004ae2:	fc26                	sd	s1,56(sp)
    80004ae4:	f84a                	sd	s2,48(sp)
    80004ae6:	f44e                	sd	s3,40(sp)
    80004ae8:	0880                	add	s0,sp,80
    80004aea:	84aa                	mv	s1,a0
    80004aec:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004aee:	ffffd097          	auipc	ra,0xffffd
    80004af2:	f54080e7          	jalr	-172(ra) # 80001a42 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004af6:	409c                	lw	a5,0(s1)
    80004af8:	37f9                	addw	a5,a5,-2
    80004afa:	4705                	li	a4,1
    80004afc:	04f76763          	bltu	a4,a5,80004b4a <filestat+0x6e>
    80004b00:	892a                	mv	s2,a0
    ilock(f->ip);
    80004b02:	6c88                	ld	a0,24(s1)
    80004b04:	fffff097          	auipc	ra,0xfffff
    80004b08:	0a6080e7          	jalr	166(ra) # 80003baa <ilock>
    stati(f->ip, &st);
    80004b0c:	fb840593          	add	a1,s0,-72
    80004b10:	6c88                	ld	a0,24(s1)
    80004b12:	fffff097          	auipc	ra,0xfffff
    80004b16:	322080e7          	jalr	802(ra) # 80003e34 <stati>
    iunlock(f->ip);
    80004b1a:	6c88                	ld	a0,24(s1)
    80004b1c:	fffff097          	auipc	ra,0xfffff
    80004b20:	150080e7          	jalr	336(ra) # 80003c6c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004b24:	46e1                	li	a3,24
    80004b26:	fb840613          	add	a2,s0,-72
    80004b2a:	85ce                	mv	a1,s3
    80004b2c:	05093503          	ld	a0,80(s2)
    80004b30:	ffffd097          	auipc	ra,0xffffd
    80004b34:	bd2080e7          	jalr	-1070(ra) # 80001702 <copyout>
    80004b38:	41f5551b          	sraw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004b3c:	60a6                	ld	ra,72(sp)
    80004b3e:	6406                	ld	s0,64(sp)
    80004b40:	74e2                	ld	s1,56(sp)
    80004b42:	7942                	ld	s2,48(sp)
    80004b44:	79a2                	ld	s3,40(sp)
    80004b46:	6161                	add	sp,sp,80
    80004b48:	8082                	ret
  return -1;
    80004b4a:	557d                	li	a0,-1
    80004b4c:	bfc5                	j	80004b3c <filestat+0x60>

0000000080004b4e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004b4e:	7179                	add	sp,sp,-48
    80004b50:	f406                	sd	ra,40(sp)
    80004b52:	f022                	sd	s0,32(sp)
    80004b54:	ec26                	sd	s1,24(sp)
    80004b56:	e84a                	sd	s2,16(sp)
    80004b58:	e44e                	sd	s3,8(sp)
    80004b5a:	1800                	add	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004b5c:	00854783          	lbu	a5,8(a0)
    80004b60:	c3d5                	beqz	a5,80004c04 <fileread+0xb6>
    80004b62:	84aa                	mv	s1,a0
    80004b64:	89ae                	mv	s3,a1
    80004b66:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b68:	411c                	lw	a5,0(a0)
    80004b6a:	4705                	li	a4,1
    80004b6c:	04e78963          	beq	a5,a4,80004bbe <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b70:	470d                	li	a4,3
    80004b72:	04e78d63          	beq	a5,a4,80004bcc <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b76:	4709                	li	a4,2
    80004b78:	06e79e63          	bne	a5,a4,80004bf4 <fileread+0xa6>
    ilock(f->ip);
    80004b7c:	6d08                	ld	a0,24(a0)
    80004b7e:	fffff097          	auipc	ra,0xfffff
    80004b82:	02c080e7          	jalr	44(ra) # 80003baa <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004b86:	874a                	mv	a4,s2
    80004b88:	5094                	lw	a3,32(s1)
    80004b8a:	864e                	mv	a2,s3
    80004b8c:	4585                	li	a1,1
    80004b8e:	6c88                	ld	a0,24(s1)
    80004b90:	fffff097          	auipc	ra,0xfffff
    80004b94:	2ce080e7          	jalr	718(ra) # 80003e5e <readi>
    80004b98:	892a                	mv	s2,a0
    80004b9a:	00a05563          	blez	a0,80004ba4 <fileread+0x56>
      f->off += r;
    80004b9e:	509c                	lw	a5,32(s1)
    80004ba0:	9fa9                	addw	a5,a5,a0
    80004ba2:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004ba4:	6c88                	ld	a0,24(s1)
    80004ba6:	fffff097          	auipc	ra,0xfffff
    80004baa:	0c6080e7          	jalr	198(ra) # 80003c6c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004bae:	854a                	mv	a0,s2
    80004bb0:	70a2                	ld	ra,40(sp)
    80004bb2:	7402                	ld	s0,32(sp)
    80004bb4:	64e2                	ld	s1,24(sp)
    80004bb6:	6942                	ld	s2,16(sp)
    80004bb8:	69a2                	ld	s3,8(sp)
    80004bba:	6145                	add	sp,sp,48
    80004bbc:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004bbe:	6908                	ld	a0,16(a0)
    80004bc0:	00000097          	auipc	ra,0x0
    80004bc4:	3c2080e7          	jalr	962(ra) # 80004f82 <piperead>
    80004bc8:	892a                	mv	s2,a0
    80004bca:	b7d5                	j	80004bae <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004bcc:	02451783          	lh	a5,36(a0)
    80004bd0:	03079693          	sll	a3,a5,0x30
    80004bd4:	92c1                	srl	a3,a3,0x30
    80004bd6:	4725                	li	a4,9
    80004bd8:	02d76863          	bltu	a4,a3,80004c08 <fileread+0xba>
    80004bdc:	0792                	sll	a5,a5,0x4
    80004bde:	0023d717          	auipc	a4,0x23d
    80004be2:	80a70713          	add	a4,a4,-2038 # 802413e8 <devsw>
    80004be6:	97ba                	add	a5,a5,a4
    80004be8:	639c                	ld	a5,0(a5)
    80004bea:	c38d                	beqz	a5,80004c0c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004bec:	4505                	li	a0,1
    80004bee:	9782                	jalr	a5
    80004bf0:	892a                	mv	s2,a0
    80004bf2:	bf75                	j	80004bae <fileread+0x60>
    panic("fileread");
    80004bf4:	00004517          	auipc	a0,0x4
    80004bf8:	af450513          	add	a0,a0,-1292 # 800086e8 <syscalls+0x270>
    80004bfc:	ffffc097          	auipc	ra,0xffffc
    80004c00:	940080e7          	jalr	-1728(ra) # 8000053c <panic>
    return -1;
    80004c04:	597d                	li	s2,-1
    80004c06:	b765                	j	80004bae <fileread+0x60>
      return -1;
    80004c08:	597d                	li	s2,-1
    80004c0a:	b755                	j	80004bae <fileread+0x60>
    80004c0c:	597d                	li	s2,-1
    80004c0e:	b745                	j	80004bae <fileread+0x60>

0000000080004c10 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004c10:	00954783          	lbu	a5,9(a0)
    80004c14:	10078e63          	beqz	a5,80004d30 <filewrite+0x120>
{
    80004c18:	715d                	add	sp,sp,-80
    80004c1a:	e486                	sd	ra,72(sp)
    80004c1c:	e0a2                	sd	s0,64(sp)
    80004c1e:	fc26                	sd	s1,56(sp)
    80004c20:	f84a                	sd	s2,48(sp)
    80004c22:	f44e                	sd	s3,40(sp)
    80004c24:	f052                	sd	s4,32(sp)
    80004c26:	ec56                	sd	s5,24(sp)
    80004c28:	e85a                	sd	s6,16(sp)
    80004c2a:	e45e                	sd	s7,8(sp)
    80004c2c:	e062                	sd	s8,0(sp)
    80004c2e:	0880                	add	s0,sp,80
    80004c30:	892a                	mv	s2,a0
    80004c32:	8b2e                	mv	s6,a1
    80004c34:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c36:	411c                	lw	a5,0(a0)
    80004c38:	4705                	li	a4,1
    80004c3a:	02e78263          	beq	a5,a4,80004c5e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c3e:	470d                	li	a4,3
    80004c40:	02e78563          	beq	a5,a4,80004c6a <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c44:	4709                	li	a4,2
    80004c46:	0ce79d63          	bne	a5,a4,80004d20 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004c4a:	0ac05b63          	blez	a2,80004d00 <filewrite+0xf0>
    int i = 0;
    80004c4e:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004c50:	6b85                	lui	s7,0x1
    80004c52:	c00b8b93          	add	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004c56:	6c05                	lui	s8,0x1
    80004c58:	c00c0c1b          	addw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004c5c:	a851                	j	80004cf0 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004c5e:	6908                	ld	a0,16(a0)
    80004c60:	00000097          	auipc	ra,0x0
    80004c64:	22a080e7          	jalr	554(ra) # 80004e8a <pipewrite>
    80004c68:	a045                	j	80004d08 <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c6a:	02451783          	lh	a5,36(a0)
    80004c6e:	03079693          	sll	a3,a5,0x30
    80004c72:	92c1                	srl	a3,a3,0x30
    80004c74:	4725                	li	a4,9
    80004c76:	0ad76f63          	bltu	a4,a3,80004d34 <filewrite+0x124>
    80004c7a:	0792                	sll	a5,a5,0x4
    80004c7c:	0023c717          	auipc	a4,0x23c
    80004c80:	76c70713          	add	a4,a4,1900 # 802413e8 <devsw>
    80004c84:	97ba                	add	a5,a5,a4
    80004c86:	679c                	ld	a5,8(a5)
    80004c88:	cbc5                	beqz	a5,80004d38 <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004c8a:	4505                	li	a0,1
    80004c8c:	9782                	jalr	a5
    80004c8e:	a8ad                	j	80004d08 <filewrite+0xf8>
      if(n1 > max)
    80004c90:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004c94:	00000097          	auipc	ra,0x0
    80004c98:	8bc080e7          	jalr	-1860(ra) # 80004550 <begin_op>
      ilock(f->ip);
    80004c9c:	01893503          	ld	a0,24(s2)
    80004ca0:	fffff097          	auipc	ra,0xfffff
    80004ca4:	f0a080e7          	jalr	-246(ra) # 80003baa <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004ca8:	8756                	mv	a4,s5
    80004caa:	02092683          	lw	a3,32(s2)
    80004cae:	01698633          	add	a2,s3,s6
    80004cb2:	4585                	li	a1,1
    80004cb4:	01893503          	ld	a0,24(s2)
    80004cb8:	fffff097          	auipc	ra,0xfffff
    80004cbc:	29e080e7          	jalr	670(ra) # 80003f56 <writei>
    80004cc0:	84aa                	mv	s1,a0
    80004cc2:	00a05763          	blez	a0,80004cd0 <filewrite+0xc0>
        f->off += r;
    80004cc6:	02092783          	lw	a5,32(s2)
    80004cca:	9fa9                	addw	a5,a5,a0
    80004ccc:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004cd0:	01893503          	ld	a0,24(s2)
    80004cd4:	fffff097          	auipc	ra,0xfffff
    80004cd8:	f98080e7          	jalr	-104(ra) # 80003c6c <iunlock>
      end_op();
    80004cdc:	00000097          	auipc	ra,0x0
    80004ce0:	8ee080e7          	jalr	-1810(ra) # 800045ca <end_op>

      if(r != n1){
    80004ce4:	009a9f63          	bne	s5,s1,80004d02 <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004ce8:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004cec:	0149db63          	bge	s3,s4,80004d02 <filewrite+0xf2>
      int n1 = n - i;
    80004cf0:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004cf4:	0004879b          	sext.w	a5,s1
    80004cf8:	f8fbdce3          	bge	s7,a5,80004c90 <filewrite+0x80>
    80004cfc:	84e2                	mv	s1,s8
    80004cfe:	bf49                	j	80004c90 <filewrite+0x80>
    int i = 0;
    80004d00:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004d02:	033a1d63          	bne	s4,s3,80004d3c <filewrite+0x12c>
    80004d06:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004d08:	60a6                	ld	ra,72(sp)
    80004d0a:	6406                	ld	s0,64(sp)
    80004d0c:	74e2                	ld	s1,56(sp)
    80004d0e:	7942                	ld	s2,48(sp)
    80004d10:	79a2                	ld	s3,40(sp)
    80004d12:	7a02                	ld	s4,32(sp)
    80004d14:	6ae2                	ld	s5,24(sp)
    80004d16:	6b42                	ld	s6,16(sp)
    80004d18:	6ba2                	ld	s7,8(sp)
    80004d1a:	6c02                	ld	s8,0(sp)
    80004d1c:	6161                	add	sp,sp,80
    80004d1e:	8082                	ret
    panic("filewrite");
    80004d20:	00004517          	auipc	a0,0x4
    80004d24:	9d850513          	add	a0,a0,-1576 # 800086f8 <syscalls+0x280>
    80004d28:	ffffc097          	auipc	ra,0xffffc
    80004d2c:	814080e7          	jalr	-2028(ra) # 8000053c <panic>
    return -1;
    80004d30:	557d                	li	a0,-1
}
    80004d32:	8082                	ret
      return -1;
    80004d34:	557d                	li	a0,-1
    80004d36:	bfc9                	j	80004d08 <filewrite+0xf8>
    80004d38:	557d                	li	a0,-1
    80004d3a:	b7f9                	j	80004d08 <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80004d3c:	557d                	li	a0,-1
    80004d3e:	b7e9                	j	80004d08 <filewrite+0xf8>

0000000080004d40 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004d40:	7179                	add	sp,sp,-48
    80004d42:	f406                	sd	ra,40(sp)
    80004d44:	f022                	sd	s0,32(sp)
    80004d46:	ec26                	sd	s1,24(sp)
    80004d48:	e84a                	sd	s2,16(sp)
    80004d4a:	e44e                	sd	s3,8(sp)
    80004d4c:	e052                	sd	s4,0(sp)
    80004d4e:	1800                	add	s0,sp,48
    80004d50:	84aa                	mv	s1,a0
    80004d52:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004d54:	0005b023          	sd	zero,0(a1)
    80004d58:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004d5c:	00000097          	auipc	ra,0x0
    80004d60:	bfc080e7          	jalr	-1028(ra) # 80004958 <filealloc>
    80004d64:	e088                	sd	a0,0(s1)
    80004d66:	c551                	beqz	a0,80004df2 <pipealloc+0xb2>
    80004d68:	00000097          	auipc	ra,0x0
    80004d6c:	bf0080e7          	jalr	-1040(ra) # 80004958 <filealloc>
    80004d70:	00aa3023          	sd	a0,0(s4)
    80004d74:	c92d                	beqz	a0,80004de6 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004d76:	ffffc097          	auipc	ra,0xffffc
    80004d7a:	dd8080e7          	jalr	-552(ra) # 80000b4e <kalloc>
    80004d7e:	892a                	mv	s2,a0
    80004d80:	c125                	beqz	a0,80004de0 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004d82:	4985                	li	s3,1
    80004d84:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004d88:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004d8c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004d90:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004d94:	00004597          	auipc	a1,0x4
    80004d98:	97458593          	add	a1,a1,-1676 # 80008708 <syscalls+0x290>
    80004d9c:	ffffc097          	auipc	ra,0xffffc
    80004da0:	e70080e7          	jalr	-400(ra) # 80000c0c <initlock>
  (*f0)->type = FD_PIPE;
    80004da4:	609c                	ld	a5,0(s1)
    80004da6:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004daa:	609c                	ld	a5,0(s1)
    80004dac:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004db0:	609c                	ld	a5,0(s1)
    80004db2:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004db6:	609c                	ld	a5,0(s1)
    80004db8:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004dbc:	000a3783          	ld	a5,0(s4)
    80004dc0:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004dc4:	000a3783          	ld	a5,0(s4)
    80004dc8:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004dcc:	000a3783          	ld	a5,0(s4)
    80004dd0:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004dd4:	000a3783          	ld	a5,0(s4)
    80004dd8:	0127b823          	sd	s2,16(a5)
  return 0;
    80004ddc:	4501                	li	a0,0
    80004dde:	a025                	j	80004e06 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004de0:	6088                	ld	a0,0(s1)
    80004de2:	e501                	bnez	a0,80004dea <pipealloc+0xaa>
    80004de4:	a039                	j	80004df2 <pipealloc+0xb2>
    80004de6:	6088                	ld	a0,0(s1)
    80004de8:	c51d                	beqz	a0,80004e16 <pipealloc+0xd6>
    fileclose(*f0);
    80004dea:	00000097          	auipc	ra,0x0
    80004dee:	c2a080e7          	jalr	-982(ra) # 80004a14 <fileclose>
  if(*f1)
    80004df2:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004df6:	557d                	li	a0,-1
  if(*f1)
    80004df8:	c799                	beqz	a5,80004e06 <pipealloc+0xc6>
    fileclose(*f1);
    80004dfa:	853e                	mv	a0,a5
    80004dfc:	00000097          	auipc	ra,0x0
    80004e00:	c18080e7          	jalr	-1000(ra) # 80004a14 <fileclose>
  return -1;
    80004e04:	557d                	li	a0,-1
}
    80004e06:	70a2                	ld	ra,40(sp)
    80004e08:	7402                	ld	s0,32(sp)
    80004e0a:	64e2                	ld	s1,24(sp)
    80004e0c:	6942                	ld	s2,16(sp)
    80004e0e:	69a2                	ld	s3,8(sp)
    80004e10:	6a02                	ld	s4,0(sp)
    80004e12:	6145                	add	sp,sp,48
    80004e14:	8082                	ret
  return -1;
    80004e16:	557d                	li	a0,-1
    80004e18:	b7fd                	j	80004e06 <pipealloc+0xc6>

0000000080004e1a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004e1a:	1101                	add	sp,sp,-32
    80004e1c:	ec06                	sd	ra,24(sp)
    80004e1e:	e822                	sd	s0,16(sp)
    80004e20:	e426                	sd	s1,8(sp)
    80004e22:	e04a                	sd	s2,0(sp)
    80004e24:	1000                	add	s0,sp,32
    80004e26:	84aa                	mv	s1,a0
    80004e28:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004e2a:	ffffc097          	auipc	ra,0xffffc
    80004e2e:	e72080e7          	jalr	-398(ra) # 80000c9c <acquire>
  if(writable){
    80004e32:	02090d63          	beqz	s2,80004e6c <pipeclose+0x52>
    pi->writeopen = 0;
    80004e36:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004e3a:	21848513          	add	a0,s1,536
    80004e3e:	ffffd097          	auipc	ra,0xffffd
    80004e42:	51c080e7          	jalr	1308(ra) # 8000235a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004e46:	2204b783          	ld	a5,544(s1)
    80004e4a:	eb95                	bnez	a5,80004e7e <pipeclose+0x64>
    release(&pi->lock);
    80004e4c:	8526                	mv	a0,s1
    80004e4e:	ffffc097          	auipc	ra,0xffffc
    80004e52:	f02080e7          	jalr	-254(ra) # 80000d50 <release>
    kfree((char*)pi);
    80004e56:	8526                	mv	a0,s1
    80004e58:	ffffc097          	auipc	ra,0xffffc
    80004e5c:	b8c080e7          	jalr	-1140(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    80004e60:	60e2                	ld	ra,24(sp)
    80004e62:	6442                	ld	s0,16(sp)
    80004e64:	64a2                	ld	s1,8(sp)
    80004e66:	6902                	ld	s2,0(sp)
    80004e68:	6105                	add	sp,sp,32
    80004e6a:	8082                	ret
    pi->readopen = 0;
    80004e6c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004e70:	21c48513          	add	a0,s1,540
    80004e74:	ffffd097          	auipc	ra,0xffffd
    80004e78:	4e6080e7          	jalr	1254(ra) # 8000235a <wakeup>
    80004e7c:	b7e9                	j	80004e46 <pipeclose+0x2c>
    release(&pi->lock);
    80004e7e:	8526                	mv	a0,s1
    80004e80:	ffffc097          	auipc	ra,0xffffc
    80004e84:	ed0080e7          	jalr	-304(ra) # 80000d50 <release>
}
    80004e88:	bfe1                	j	80004e60 <pipeclose+0x46>

0000000080004e8a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004e8a:	711d                	add	sp,sp,-96
    80004e8c:	ec86                	sd	ra,88(sp)
    80004e8e:	e8a2                	sd	s0,80(sp)
    80004e90:	e4a6                	sd	s1,72(sp)
    80004e92:	e0ca                	sd	s2,64(sp)
    80004e94:	fc4e                	sd	s3,56(sp)
    80004e96:	f852                	sd	s4,48(sp)
    80004e98:	f456                	sd	s5,40(sp)
    80004e9a:	f05a                	sd	s6,32(sp)
    80004e9c:	ec5e                	sd	s7,24(sp)
    80004e9e:	e862                	sd	s8,16(sp)
    80004ea0:	1080                	add	s0,sp,96
    80004ea2:	84aa                	mv	s1,a0
    80004ea4:	8aae                	mv	s5,a1
    80004ea6:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ea8:	ffffd097          	auipc	ra,0xffffd
    80004eac:	b9a080e7          	jalr	-1126(ra) # 80001a42 <myproc>
    80004eb0:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004eb2:	8526                	mv	a0,s1
    80004eb4:	ffffc097          	auipc	ra,0xffffc
    80004eb8:	de8080e7          	jalr	-536(ra) # 80000c9c <acquire>
  while(i < n){
    80004ebc:	0b405663          	blez	s4,80004f68 <pipewrite+0xde>
  int i = 0;
    80004ec0:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ec2:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004ec4:	21848c13          	add	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ec8:	21c48b93          	add	s7,s1,540
    80004ecc:	a089                	j	80004f0e <pipewrite+0x84>
      release(&pi->lock);
    80004ece:	8526                	mv	a0,s1
    80004ed0:	ffffc097          	auipc	ra,0xffffc
    80004ed4:	e80080e7          	jalr	-384(ra) # 80000d50 <release>
      return -1;
    80004ed8:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004eda:	854a                	mv	a0,s2
    80004edc:	60e6                	ld	ra,88(sp)
    80004ede:	6446                	ld	s0,80(sp)
    80004ee0:	64a6                	ld	s1,72(sp)
    80004ee2:	6906                	ld	s2,64(sp)
    80004ee4:	79e2                	ld	s3,56(sp)
    80004ee6:	7a42                	ld	s4,48(sp)
    80004ee8:	7aa2                	ld	s5,40(sp)
    80004eea:	7b02                	ld	s6,32(sp)
    80004eec:	6be2                	ld	s7,24(sp)
    80004eee:	6c42                	ld	s8,16(sp)
    80004ef0:	6125                	add	sp,sp,96
    80004ef2:	8082                	ret
      wakeup(&pi->nread);
    80004ef4:	8562                	mv	a0,s8
    80004ef6:	ffffd097          	auipc	ra,0xffffd
    80004efa:	464080e7          	jalr	1124(ra) # 8000235a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004efe:	85a6                	mv	a1,s1
    80004f00:	855e                	mv	a0,s7
    80004f02:	ffffd097          	auipc	ra,0xffffd
    80004f06:	3f4080e7          	jalr	1012(ra) # 800022f6 <sleep>
  while(i < n){
    80004f0a:	07495063          	bge	s2,s4,80004f6a <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004f0e:	2204a783          	lw	a5,544(s1)
    80004f12:	dfd5                	beqz	a5,80004ece <pipewrite+0x44>
    80004f14:	854e                	mv	a0,s3
    80004f16:	ffffd097          	auipc	ra,0xffffd
    80004f1a:	694080e7          	jalr	1684(ra) # 800025aa <killed>
    80004f1e:	f945                	bnez	a0,80004ece <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004f20:	2184a783          	lw	a5,536(s1)
    80004f24:	21c4a703          	lw	a4,540(s1)
    80004f28:	2007879b          	addw	a5,a5,512
    80004f2c:	fcf704e3          	beq	a4,a5,80004ef4 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f30:	4685                	li	a3,1
    80004f32:	01590633          	add	a2,s2,s5
    80004f36:	faf40593          	add	a1,s0,-81
    80004f3a:	0509b503          	ld	a0,80(s3)
    80004f3e:	ffffd097          	auipc	ra,0xffffd
    80004f42:	850080e7          	jalr	-1968(ra) # 8000178e <copyin>
    80004f46:	03650263          	beq	a0,s6,80004f6a <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f4a:	21c4a783          	lw	a5,540(s1)
    80004f4e:	0017871b          	addw	a4,a5,1
    80004f52:	20e4ae23          	sw	a4,540(s1)
    80004f56:	1ff7f793          	and	a5,a5,511
    80004f5a:	97a6                	add	a5,a5,s1
    80004f5c:	faf44703          	lbu	a4,-81(s0)
    80004f60:	00e78c23          	sb	a4,24(a5)
      i++;
    80004f64:	2905                	addw	s2,s2,1
    80004f66:	b755                	j	80004f0a <pipewrite+0x80>
  int i = 0;
    80004f68:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004f6a:	21848513          	add	a0,s1,536
    80004f6e:	ffffd097          	auipc	ra,0xffffd
    80004f72:	3ec080e7          	jalr	1004(ra) # 8000235a <wakeup>
  release(&pi->lock);
    80004f76:	8526                	mv	a0,s1
    80004f78:	ffffc097          	auipc	ra,0xffffc
    80004f7c:	dd8080e7          	jalr	-552(ra) # 80000d50 <release>
  return i;
    80004f80:	bfa9                	j	80004eda <pipewrite+0x50>

0000000080004f82 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004f82:	715d                	add	sp,sp,-80
    80004f84:	e486                	sd	ra,72(sp)
    80004f86:	e0a2                	sd	s0,64(sp)
    80004f88:	fc26                	sd	s1,56(sp)
    80004f8a:	f84a                	sd	s2,48(sp)
    80004f8c:	f44e                	sd	s3,40(sp)
    80004f8e:	f052                	sd	s4,32(sp)
    80004f90:	ec56                	sd	s5,24(sp)
    80004f92:	e85a                	sd	s6,16(sp)
    80004f94:	0880                	add	s0,sp,80
    80004f96:	84aa                	mv	s1,a0
    80004f98:	892e                	mv	s2,a1
    80004f9a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004f9c:	ffffd097          	auipc	ra,0xffffd
    80004fa0:	aa6080e7          	jalr	-1370(ra) # 80001a42 <myproc>
    80004fa4:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004fa6:	8526                	mv	a0,s1
    80004fa8:	ffffc097          	auipc	ra,0xffffc
    80004fac:	cf4080e7          	jalr	-780(ra) # 80000c9c <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fb0:	2184a703          	lw	a4,536(s1)
    80004fb4:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004fb8:	21848993          	add	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fbc:	02f71763          	bne	a4,a5,80004fea <piperead+0x68>
    80004fc0:	2244a783          	lw	a5,548(s1)
    80004fc4:	c39d                	beqz	a5,80004fea <piperead+0x68>
    if(killed(pr)){
    80004fc6:	8552                	mv	a0,s4
    80004fc8:	ffffd097          	auipc	ra,0xffffd
    80004fcc:	5e2080e7          	jalr	1506(ra) # 800025aa <killed>
    80004fd0:	e949                	bnez	a0,80005062 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004fd2:	85a6                	mv	a1,s1
    80004fd4:	854e                	mv	a0,s3
    80004fd6:	ffffd097          	auipc	ra,0xffffd
    80004fda:	320080e7          	jalr	800(ra) # 800022f6 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fde:	2184a703          	lw	a4,536(s1)
    80004fe2:	21c4a783          	lw	a5,540(s1)
    80004fe6:	fcf70de3          	beq	a4,a5,80004fc0 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fea:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004fec:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fee:	05505463          	blez	s5,80005036 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004ff2:	2184a783          	lw	a5,536(s1)
    80004ff6:	21c4a703          	lw	a4,540(s1)
    80004ffa:	02f70e63          	beq	a4,a5,80005036 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ffe:	0017871b          	addw	a4,a5,1
    80005002:	20e4ac23          	sw	a4,536(s1)
    80005006:	1ff7f793          	and	a5,a5,511
    8000500a:	97a6                	add	a5,a5,s1
    8000500c:	0187c783          	lbu	a5,24(a5)
    80005010:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005014:	4685                	li	a3,1
    80005016:	fbf40613          	add	a2,s0,-65
    8000501a:	85ca                	mv	a1,s2
    8000501c:	050a3503          	ld	a0,80(s4)
    80005020:	ffffc097          	auipc	ra,0xffffc
    80005024:	6e2080e7          	jalr	1762(ra) # 80001702 <copyout>
    80005028:	01650763          	beq	a0,s6,80005036 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000502c:	2985                	addw	s3,s3,1
    8000502e:	0905                	add	s2,s2,1
    80005030:	fd3a91e3          	bne	s5,s3,80004ff2 <piperead+0x70>
    80005034:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005036:	21c48513          	add	a0,s1,540
    8000503a:	ffffd097          	auipc	ra,0xffffd
    8000503e:	320080e7          	jalr	800(ra) # 8000235a <wakeup>
  release(&pi->lock);
    80005042:	8526                	mv	a0,s1
    80005044:	ffffc097          	auipc	ra,0xffffc
    80005048:	d0c080e7          	jalr	-756(ra) # 80000d50 <release>
  return i;
}
    8000504c:	854e                	mv	a0,s3
    8000504e:	60a6                	ld	ra,72(sp)
    80005050:	6406                	ld	s0,64(sp)
    80005052:	74e2                	ld	s1,56(sp)
    80005054:	7942                	ld	s2,48(sp)
    80005056:	79a2                	ld	s3,40(sp)
    80005058:	7a02                	ld	s4,32(sp)
    8000505a:	6ae2                	ld	s5,24(sp)
    8000505c:	6b42                	ld	s6,16(sp)
    8000505e:	6161                	add	sp,sp,80
    80005060:	8082                	ret
      release(&pi->lock);
    80005062:	8526                	mv	a0,s1
    80005064:	ffffc097          	auipc	ra,0xffffc
    80005068:	cec080e7          	jalr	-788(ra) # 80000d50 <release>
      return -1;
    8000506c:	59fd                	li	s3,-1
    8000506e:	bff9                	j	8000504c <piperead+0xca>

0000000080005070 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005070:	1141                	add	sp,sp,-16
    80005072:	e422                	sd	s0,8(sp)
    80005074:	0800                	add	s0,sp,16
    80005076:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005078:	8905                	and	a0,a0,1
    8000507a:	050e                	sll	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    8000507c:	8b89                	and	a5,a5,2
    8000507e:	c399                	beqz	a5,80005084 <flags2perm+0x14>
      perm |= PTE_W;
    80005080:	00456513          	or	a0,a0,4
    return perm;
}
    80005084:	6422                	ld	s0,8(sp)
    80005086:	0141                	add	sp,sp,16
    80005088:	8082                	ret

000000008000508a <exec>:

int
exec(char *path, char **argv)
{
    8000508a:	df010113          	add	sp,sp,-528
    8000508e:	20113423          	sd	ra,520(sp)
    80005092:	20813023          	sd	s0,512(sp)
    80005096:	ffa6                	sd	s1,504(sp)
    80005098:	fbca                	sd	s2,496(sp)
    8000509a:	f7ce                	sd	s3,488(sp)
    8000509c:	f3d2                	sd	s4,480(sp)
    8000509e:	efd6                	sd	s5,472(sp)
    800050a0:	ebda                	sd	s6,464(sp)
    800050a2:	e7de                	sd	s7,456(sp)
    800050a4:	e3e2                	sd	s8,448(sp)
    800050a6:	ff66                	sd	s9,440(sp)
    800050a8:	fb6a                	sd	s10,432(sp)
    800050aa:	f76e                	sd	s11,424(sp)
    800050ac:	0c00                	add	s0,sp,528
    800050ae:	892a                	mv	s2,a0
    800050b0:	dea43c23          	sd	a0,-520(s0)
    800050b4:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800050b8:	ffffd097          	auipc	ra,0xffffd
    800050bc:	98a080e7          	jalr	-1654(ra) # 80001a42 <myproc>
    800050c0:	84aa                	mv	s1,a0

  begin_op();
    800050c2:	fffff097          	auipc	ra,0xfffff
    800050c6:	48e080e7          	jalr	1166(ra) # 80004550 <begin_op>

  if((ip = namei(path)) == 0){
    800050ca:	854a                	mv	a0,s2
    800050cc:	fffff097          	auipc	ra,0xfffff
    800050d0:	284080e7          	jalr	644(ra) # 80004350 <namei>
    800050d4:	c92d                	beqz	a0,80005146 <exec+0xbc>
    800050d6:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800050d8:	fffff097          	auipc	ra,0xfffff
    800050dc:	ad2080e7          	jalr	-1326(ra) # 80003baa <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800050e0:	04000713          	li	a4,64
    800050e4:	4681                	li	a3,0
    800050e6:	e5040613          	add	a2,s0,-432
    800050ea:	4581                	li	a1,0
    800050ec:	8552                	mv	a0,s4
    800050ee:	fffff097          	auipc	ra,0xfffff
    800050f2:	d70080e7          	jalr	-656(ra) # 80003e5e <readi>
    800050f6:	04000793          	li	a5,64
    800050fa:	00f51a63          	bne	a0,a5,8000510e <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800050fe:	e5042703          	lw	a4,-432(s0)
    80005102:	464c47b7          	lui	a5,0x464c4
    80005106:	57f78793          	add	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000510a:	04f70463          	beq	a4,a5,80005152 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000510e:	8552                	mv	a0,s4
    80005110:	fffff097          	auipc	ra,0xfffff
    80005114:	cfc080e7          	jalr	-772(ra) # 80003e0c <iunlockput>
    end_op();
    80005118:	fffff097          	auipc	ra,0xfffff
    8000511c:	4b2080e7          	jalr	1202(ra) # 800045ca <end_op>
  }
  return -1;
    80005120:	557d                	li	a0,-1
}
    80005122:	20813083          	ld	ra,520(sp)
    80005126:	20013403          	ld	s0,512(sp)
    8000512a:	74fe                	ld	s1,504(sp)
    8000512c:	795e                	ld	s2,496(sp)
    8000512e:	79be                	ld	s3,488(sp)
    80005130:	7a1e                	ld	s4,480(sp)
    80005132:	6afe                	ld	s5,472(sp)
    80005134:	6b5e                	ld	s6,464(sp)
    80005136:	6bbe                	ld	s7,456(sp)
    80005138:	6c1e                	ld	s8,448(sp)
    8000513a:	7cfa                	ld	s9,440(sp)
    8000513c:	7d5a                	ld	s10,432(sp)
    8000513e:	7dba                	ld	s11,424(sp)
    80005140:	21010113          	add	sp,sp,528
    80005144:	8082                	ret
    end_op();
    80005146:	fffff097          	auipc	ra,0xfffff
    8000514a:	484080e7          	jalr	1156(ra) # 800045ca <end_op>
    return -1;
    8000514e:	557d                	li	a0,-1
    80005150:	bfc9                	j	80005122 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005152:	8526                	mv	a0,s1
    80005154:	ffffd097          	auipc	ra,0xffffd
    80005158:	9b2080e7          	jalr	-1614(ra) # 80001b06 <proc_pagetable>
    8000515c:	8b2a                	mv	s6,a0
    8000515e:	d945                	beqz	a0,8000510e <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005160:	e7042d03          	lw	s10,-400(s0)
    80005164:	e8845783          	lhu	a5,-376(s0)
    80005168:	10078463          	beqz	a5,80005270 <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000516c:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000516e:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80005170:	6c85                	lui	s9,0x1
    80005172:	fffc8793          	add	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005176:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    8000517a:	6a85                	lui	s5,0x1
    8000517c:	a0b5                	j	800051e8 <exec+0x15e>
      panic("loadseg: address should exist");
    8000517e:	00003517          	auipc	a0,0x3
    80005182:	59250513          	add	a0,a0,1426 # 80008710 <syscalls+0x298>
    80005186:	ffffb097          	auipc	ra,0xffffb
    8000518a:	3b6080e7          	jalr	950(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    8000518e:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005190:	8726                	mv	a4,s1
    80005192:	012c06bb          	addw	a3,s8,s2
    80005196:	4581                	li	a1,0
    80005198:	8552                	mv	a0,s4
    8000519a:	fffff097          	auipc	ra,0xfffff
    8000519e:	cc4080e7          	jalr	-828(ra) # 80003e5e <readi>
    800051a2:	2501                	sext.w	a0,a0
    800051a4:	24a49863          	bne	s1,a0,800053f4 <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    800051a8:	012a893b          	addw	s2,s5,s2
    800051ac:	03397563          	bgeu	s2,s3,800051d6 <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    800051b0:	02091593          	sll	a1,s2,0x20
    800051b4:	9181                	srl	a1,a1,0x20
    800051b6:	95de                	add	a1,a1,s7
    800051b8:	855a                	mv	a0,s6
    800051ba:	ffffc097          	auipc	ra,0xffffc
    800051be:	f66080e7          	jalr	-154(ra) # 80001120 <walkaddr>
    800051c2:	862a                	mv	a2,a0
    if(pa == 0)
    800051c4:	dd4d                	beqz	a0,8000517e <exec+0xf4>
    if(sz - i < PGSIZE)
    800051c6:	412984bb          	subw	s1,s3,s2
    800051ca:	0004879b          	sext.w	a5,s1
    800051ce:	fcfcf0e3          	bgeu	s9,a5,8000518e <exec+0x104>
    800051d2:	84d6                	mv	s1,s5
    800051d4:	bf6d                	j	8000518e <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800051d6:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051da:	2d85                	addw	s11,s11,1
    800051dc:	038d0d1b          	addw	s10,s10,56
    800051e0:	e8845783          	lhu	a5,-376(s0)
    800051e4:	08fdd763          	bge	s11,a5,80005272 <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800051e8:	2d01                	sext.w	s10,s10
    800051ea:	03800713          	li	a4,56
    800051ee:	86ea                	mv	a3,s10
    800051f0:	e1840613          	add	a2,s0,-488
    800051f4:	4581                	li	a1,0
    800051f6:	8552                	mv	a0,s4
    800051f8:	fffff097          	auipc	ra,0xfffff
    800051fc:	c66080e7          	jalr	-922(ra) # 80003e5e <readi>
    80005200:	03800793          	li	a5,56
    80005204:	1ef51663          	bne	a0,a5,800053f0 <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    80005208:	e1842783          	lw	a5,-488(s0)
    8000520c:	4705                	li	a4,1
    8000520e:	fce796e3          	bne	a5,a4,800051da <exec+0x150>
    if(ph.memsz < ph.filesz)
    80005212:	e4043483          	ld	s1,-448(s0)
    80005216:	e3843783          	ld	a5,-456(s0)
    8000521a:	1ef4e863          	bltu	s1,a5,8000540a <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000521e:	e2843783          	ld	a5,-472(s0)
    80005222:	94be                	add	s1,s1,a5
    80005224:	1ef4e663          	bltu	s1,a5,80005410 <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    80005228:	df043703          	ld	a4,-528(s0)
    8000522c:	8ff9                	and	a5,a5,a4
    8000522e:	1e079463          	bnez	a5,80005416 <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005232:	e1c42503          	lw	a0,-484(s0)
    80005236:	00000097          	auipc	ra,0x0
    8000523a:	e3a080e7          	jalr	-454(ra) # 80005070 <flags2perm>
    8000523e:	86aa                	mv	a3,a0
    80005240:	8626                	mv	a2,s1
    80005242:	85ca                	mv	a1,s2
    80005244:	855a                	mv	a0,s6
    80005246:	ffffc097          	auipc	ra,0xffffc
    8000524a:	278080e7          	jalr	632(ra) # 800014be <uvmalloc>
    8000524e:	e0a43423          	sd	a0,-504(s0)
    80005252:	1c050563          	beqz	a0,8000541c <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005256:	e2843b83          	ld	s7,-472(s0)
    8000525a:	e2042c03          	lw	s8,-480(s0)
    8000525e:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005262:	00098463          	beqz	s3,8000526a <exec+0x1e0>
    80005266:	4901                	li	s2,0
    80005268:	b7a1                	j	800051b0 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000526a:	e0843903          	ld	s2,-504(s0)
    8000526e:	b7b5                	j	800051da <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005270:	4901                	li	s2,0
  iunlockput(ip);
    80005272:	8552                	mv	a0,s4
    80005274:	fffff097          	auipc	ra,0xfffff
    80005278:	b98080e7          	jalr	-1128(ra) # 80003e0c <iunlockput>
  end_op();
    8000527c:	fffff097          	auipc	ra,0xfffff
    80005280:	34e080e7          	jalr	846(ra) # 800045ca <end_op>
  p = myproc();
    80005284:	ffffc097          	auipc	ra,0xffffc
    80005288:	7be080e7          	jalr	1982(ra) # 80001a42 <myproc>
    8000528c:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000528e:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80005292:	6985                	lui	s3,0x1
    80005294:	19fd                	add	s3,s3,-1 # fff <_entry-0x7ffff001>
    80005296:	99ca                	add	s3,s3,s2
    80005298:	77fd                	lui	a5,0xfffff
    8000529a:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000529e:	4691                	li	a3,4
    800052a0:	6609                	lui	a2,0x2
    800052a2:	964e                	add	a2,a2,s3
    800052a4:	85ce                	mv	a1,s3
    800052a6:	855a                	mv	a0,s6
    800052a8:	ffffc097          	auipc	ra,0xffffc
    800052ac:	216080e7          	jalr	534(ra) # 800014be <uvmalloc>
    800052b0:	892a                	mv	s2,a0
    800052b2:	e0a43423          	sd	a0,-504(s0)
    800052b6:	e509                	bnez	a0,800052c0 <exec+0x236>
  if(pagetable)
    800052b8:	e1343423          	sd	s3,-504(s0)
    800052bc:	4a01                	li	s4,0
    800052be:	aa1d                	j	800053f4 <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    800052c0:	75f9                	lui	a1,0xffffe
    800052c2:	95aa                	add	a1,a1,a0
    800052c4:	855a                	mv	a0,s6
    800052c6:	ffffc097          	auipc	ra,0xffffc
    800052ca:	40a080e7          	jalr	1034(ra) # 800016d0 <uvmclear>
  stackbase = sp - PGSIZE;
    800052ce:	7bfd                	lui	s7,0xfffff
    800052d0:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    800052d2:	e0043783          	ld	a5,-512(s0)
    800052d6:	6388                	ld	a0,0(a5)
    800052d8:	c52d                	beqz	a0,80005342 <exec+0x2b8>
    800052da:	e9040993          	add	s3,s0,-368
    800052de:	f9040c13          	add	s8,s0,-112
    800052e2:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800052e4:	ffffc097          	auipc	ra,0xffffc
    800052e8:	c2e080e7          	jalr	-978(ra) # 80000f12 <strlen>
    800052ec:	0015079b          	addw	a5,a0,1
    800052f0:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800052f4:	ff07f913          	and	s2,a5,-16
    if(sp < stackbase)
    800052f8:	13796563          	bltu	s2,s7,80005422 <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800052fc:	e0043d03          	ld	s10,-512(s0)
    80005300:	000d3a03          	ld	s4,0(s10)
    80005304:	8552                	mv	a0,s4
    80005306:	ffffc097          	auipc	ra,0xffffc
    8000530a:	c0c080e7          	jalr	-1012(ra) # 80000f12 <strlen>
    8000530e:	0015069b          	addw	a3,a0,1
    80005312:	8652                	mv	a2,s4
    80005314:	85ca                	mv	a1,s2
    80005316:	855a                	mv	a0,s6
    80005318:	ffffc097          	auipc	ra,0xffffc
    8000531c:	3ea080e7          	jalr	1002(ra) # 80001702 <copyout>
    80005320:	10054363          	bltz	a0,80005426 <exec+0x39c>
    ustack[argc] = sp;
    80005324:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005328:	0485                	add	s1,s1,1
    8000532a:	008d0793          	add	a5,s10,8
    8000532e:	e0f43023          	sd	a5,-512(s0)
    80005332:	008d3503          	ld	a0,8(s10)
    80005336:	c909                	beqz	a0,80005348 <exec+0x2be>
    if(argc >= MAXARG)
    80005338:	09a1                	add	s3,s3,8
    8000533a:	fb8995e3          	bne	s3,s8,800052e4 <exec+0x25a>
  ip = 0;
    8000533e:	4a01                	li	s4,0
    80005340:	a855                	j	800053f4 <exec+0x36a>
  sp = sz;
    80005342:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80005346:	4481                	li	s1,0
  ustack[argc] = 0;
    80005348:	00349793          	sll	a5,s1,0x3
    8000534c:	f9078793          	add	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7fdbca10>
    80005350:	97a2                	add	a5,a5,s0
    80005352:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005356:	00148693          	add	a3,s1,1
    8000535a:	068e                	sll	a3,a3,0x3
    8000535c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005360:	ff097913          	and	s2,s2,-16
  sz = sz1;
    80005364:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80005368:	f57968e3          	bltu	s2,s7,800052b8 <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000536c:	e9040613          	add	a2,s0,-368
    80005370:	85ca                	mv	a1,s2
    80005372:	855a                	mv	a0,s6
    80005374:	ffffc097          	auipc	ra,0xffffc
    80005378:	38e080e7          	jalr	910(ra) # 80001702 <copyout>
    8000537c:	0a054763          	bltz	a0,8000542a <exec+0x3a0>
  p->trapframe->a1 = sp;
    80005380:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80005384:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005388:	df843783          	ld	a5,-520(s0)
    8000538c:	0007c703          	lbu	a4,0(a5)
    80005390:	cf11                	beqz	a4,800053ac <exec+0x322>
    80005392:	0785                	add	a5,a5,1
    if(*s == '/')
    80005394:	02f00693          	li	a3,47
    80005398:	a039                	j	800053a6 <exec+0x31c>
      last = s+1;
    8000539a:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000539e:	0785                	add	a5,a5,1
    800053a0:	fff7c703          	lbu	a4,-1(a5)
    800053a4:	c701                	beqz	a4,800053ac <exec+0x322>
    if(*s == '/')
    800053a6:	fed71ce3          	bne	a4,a3,8000539e <exec+0x314>
    800053aa:	bfc5                	j	8000539a <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    800053ac:	4641                	li	a2,16
    800053ae:	df843583          	ld	a1,-520(s0)
    800053b2:	158a8513          	add	a0,s5,344
    800053b6:	ffffc097          	auipc	ra,0xffffc
    800053ba:	b2a080e7          	jalr	-1238(ra) # 80000ee0 <safestrcpy>
  oldpagetable = p->pagetable;
    800053be:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800053c2:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    800053c6:	e0843783          	ld	a5,-504(s0)
    800053ca:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800053ce:	058ab783          	ld	a5,88(s5)
    800053d2:	e6843703          	ld	a4,-408(s0)
    800053d6:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800053d8:	058ab783          	ld	a5,88(s5)
    800053dc:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800053e0:	85e6                	mv	a1,s9
    800053e2:	ffffc097          	auipc	ra,0xffffc
    800053e6:	7c0080e7          	jalr	1984(ra) # 80001ba2 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800053ea:	0004851b          	sext.w	a0,s1
    800053ee:	bb15                	j	80005122 <exec+0x98>
    800053f0:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800053f4:	e0843583          	ld	a1,-504(s0)
    800053f8:	855a                	mv	a0,s6
    800053fa:	ffffc097          	auipc	ra,0xffffc
    800053fe:	7a8080e7          	jalr	1960(ra) # 80001ba2 <proc_freepagetable>
  return -1;
    80005402:	557d                	li	a0,-1
  if(ip){
    80005404:	d00a0fe3          	beqz	s4,80005122 <exec+0x98>
    80005408:	b319                	j	8000510e <exec+0x84>
    8000540a:	e1243423          	sd	s2,-504(s0)
    8000540e:	b7dd                	j	800053f4 <exec+0x36a>
    80005410:	e1243423          	sd	s2,-504(s0)
    80005414:	b7c5                	j	800053f4 <exec+0x36a>
    80005416:	e1243423          	sd	s2,-504(s0)
    8000541a:	bfe9                	j	800053f4 <exec+0x36a>
    8000541c:	e1243423          	sd	s2,-504(s0)
    80005420:	bfd1                	j	800053f4 <exec+0x36a>
  ip = 0;
    80005422:	4a01                	li	s4,0
    80005424:	bfc1                	j	800053f4 <exec+0x36a>
    80005426:	4a01                	li	s4,0
  if(pagetable)
    80005428:	b7f1                	j	800053f4 <exec+0x36a>
  sz = sz1;
    8000542a:	e0843983          	ld	s3,-504(s0)
    8000542e:	b569                	j	800052b8 <exec+0x22e>

0000000080005430 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005430:	7179                	add	sp,sp,-48
    80005432:	f406                	sd	ra,40(sp)
    80005434:	f022                	sd	s0,32(sp)
    80005436:	ec26                	sd	s1,24(sp)
    80005438:	e84a                	sd	s2,16(sp)
    8000543a:	1800                	add	s0,sp,48
    8000543c:	892e                	mv	s2,a1
    8000543e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005440:	fdc40593          	add	a1,s0,-36
    80005444:	ffffe097          	auipc	ra,0xffffe
    80005448:	b5a080e7          	jalr	-1190(ra) # 80002f9e <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000544c:	fdc42703          	lw	a4,-36(s0)
    80005450:	47bd                	li	a5,15
    80005452:	02e7eb63          	bltu	a5,a4,80005488 <argfd+0x58>
    80005456:	ffffc097          	auipc	ra,0xffffc
    8000545a:	5ec080e7          	jalr	1516(ra) # 80001a42 <myproc>
    8000545e:	fdc42703          	lw	a4,-36(s0)
    80005462:	01a70793          	add	a5,a4,26
    80005466:	078e                	sll	a5,a5,0x3
    80005468:	953e                	add	a0,a0,a5
    8000546a:	611c                	ld	a5,0(a0)
    8000546c:	c385                	beqz	a5,8000548c <argfd+0x5c>
    return -1;
  if(pfd)
    8000546e:	00090463          	beqz	s2,80005476 <argfd+0x46>
    *pfd = fd;
    80005472:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005476:	4501                	li	a0,0
  if(pf)
    80005478:	c091                	beqz	s1,8000547c <argfd+0x4c>
    *pf = f;
    8000547a:	e09c                	sd	a5,0(s1)
}
    8000547c:	70a2                	ld	ra,40(sp)
    8000547e:	7402                	ld	s0,32(sp)
    80005480:	64e2                	ld	s1,24(sp)
    80005482:	6942                	ld	s2,16(sp)
    80005484:	6145                	add	sp,sp,48
    80005486:	8082                	ret
    return -1;
    80005488:	557d                	li	a0,-1
    8000548a:	bfcd                	j	8000547c <argfd+0x4c>
    8000548c:	557d                	li	a0,-1
    8000548e:	b7fd                	j	8000547c <argfd+0x4c>

0000000080005490 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005490:	1101                	add	sp,sp,-32
    80005492:	ec06                	sd	ra,24(sp)
    80005494:	e822                	sd	s0,16(sp)
    80005496:	e426                	sd	s1,8(sp)
    80005498:	1000                	add	s0,sp,32
    8000549a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000549c:	ffffc097          	auipc	ra,0xffffc
    800054a0:	5a6080e7          	jalr	1446(ra) # 80001a42 <myproc>
    800054a4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800054a6:	0d050793          	add	a5,a0,208
    800054aa:	4501                	li	a0,0
    800054ac:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800054ae:	6398                	ld	a4,0(a5)
    800054b0:	cb19                	beqz	a4,800054c6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800054b2:	2505                	addw	a0,a0,1
    800054b4:	07a1                	add	a5,a5,8
    800054b6:	fed51ce3          	bne	a0,a3,800054ae <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800054ba:	557d                	li	a0,-1
}
    800054bc:	60e2                	ld	ra,24(sp)
    800054be:	6442                	ld	s0,16(sp)
    800054c0:	64a2                	ld	s1,8(sp)
    800054c2:	6105                	add	sp,sp,32
    800054c4:	8082                	ret
      p->ofile[fd] = f;
    800054c6:	01a50793          	add	a5,a0,26
    800054ca:	078e                	sll	a5,a5,0x3
    800054cc:	963e                	add	a2,a2,a5
    800054ce:	e204                	sd	s1,0(a2)
      return fd;
    800054d0:	b7f5                	j	800054bc <fdalloc+0x2c>

00000000800054d2 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800054d2:	715d                	add	sp,sp,-80
    800054d4:	e486                	sd	ra,72(sp)
    800054d6:	e0a2                	sd	s0,64(sp)
    800054d8:	fc26                	sd	s1,56(sp)
    800054da:	f84a                	sd	s2,48(sp)
    800054dc:	f44e                	sd	s3,40(sp)
    800054de:	f052                	sd	s4,32(sp)
    800054e0:	ec56                	sd	s5,24(sp)
    800054e2:	e85a                	sd	s6,16(sp)
    800054e4:	0880                	add	s0,sp,80
    800054e6:	8b2e                	mv	s6,a1
    800054e8:	89b2                	mv	s3,a2
    800054ea:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800054ec:	fb040593          	add	a1,s0,-80
    800054f0:	fffff097          	auipc	ra,0xfffff
    800054f4:	e7e080e7          	jalr	-386(ra) # 8000436e <nameiparent>
    800054f8:	84aa                	mv	s1,a0
    800054fa:	14050b63          	beqz	a0,80005650 <create+0x17e>
    return 0;

  ilock(dp);
    800054fe:	ffffe097          	auipc	ra,0xffffe
    80005502:	6ac080e7          	jalr	1708(ra) # 80003baa <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005506:	4601                	li	a2,0
    80005508:	fb040593          	add	a1,s0,-80
    8000550c:	8526                	mv	a0,s1
    8000550e:	fffff097          	auipc	ra,0xfffff
    80005512:	b80080e7          	jalr	-1152(ra) # 8000408e <dirlookup>
    80005516:	8aaa                	mv	s5,a0
    80005518:	c921                	beqz	a0,80005568 <create+0x96>
    iunlockput(dp);
    8000551a:	8526                	mv	a0,s1
    8000551c:	fffff097          	auipc	ra,0xfffff
    80005520:	8f0080e7          	jalr	-1808(ra) # 80003e0c <iunlockput>
    ilock(ip);
    80005524:	8556                	mv	a0,s5
    80005526:	ffffe097          	auipc	ra,0xffffe
    8000552a:	684080e7          	jalr	1668(ra) # 80003baa <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000552e:	4789                	li	a5,2
    80005530:	02fb1563          	bne	s6,a5,8000555a <create+0x88>
    80005534:	044ad783          	lhu	a5,68(s5)
    80005538:	37f9                	addw	a5,a5,-2
    8000553a:	17c2                	sll	a5,a5,0x30
    8000553c:	93c1                	srl	a5,a5,0x30
    8000553e:	4705                	li	a4,1
    80005540:	00f76d63          	bltu	a4,a5,8000555a <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005544:	8556                	mv	a0,s5
    80005546:	60a6                	ld	ra,72(sp)
    80005548:	6406                	ld	s0,64(sp)
    8000554a:	74e2                	ld	s1,56(sp)
    8000554c:	7942                	ld	s2,48(sp)
    8000554e:	79a2                	ld	s3,40(sp)
    80005550:	7a02                	ld	s4,32(sp)
    80005552:	6ae2                	ld	s5,24(sp)
    80005554:	6b42                	ld	s6,16(sp)
    80005556:	6161                	add	sp,sp,80
    80005558:	8082                	ret
    iunlockput(ip);
    8000555a:	8556                	mv	a0,s5
    8000555c:	fffff097          	auipc	ra,0xfffff
    80005560:	8b0080e7          	jalr	-1872(ra) # 80003e0c <iunlockput>
    return 0;
    80005564:	4a81                	li	s5,0
    80005566:	bff9                	j	80005544 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005568:	85da                	mv	a1,s6
    8000556a:	4088                	lw	a0,0(s1)
    8000556c:	ffffe097          	auipc	ra,0xffffe
    80005570:	4a6080e7          	jalr	1190(ra) # 80003a12 <ialloc>
    80005574:	8a2a                	mv	s4,a0
    80005576:	c529                	beqz	a0,800055c0 <create+0xee>
  ilock(ip);
    80005578:	ffffe097          	auipc	ra,0xffffe
    8000557c:	632080e7          	jalr	1586(ra) # 80003baa <ilock>
  ip->major = major;
    80005580:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005584:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005588:	4905                	li	s2,1
    8000558a:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000558e:	8552                	mv	a0,s4
    80005590:	ffffe097          	auipc	ra,0xffffe
    80005594:	54e080e7          	jalr	1358(ra) # 80003ade <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005598:	032b0b63          	beq	s6,s2,800055ce <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000559c:	004a2603          	lw	a2,4(s4)
    800055a0:	fb040593          	add	a1,s0,-80
    800055a4:	8526                	mv	a0,s1
    800055a6:	fffff097          	auipc	ra,0xfffff
    800055aa:	cf8080e7          	jalr	-776(ra) # 8000429e <dirlink>
    800055ae:	06054f63          	bltz	a0,8000562c <create+0x15a>
  iunlockput(dp);
    800055b2:	8526                	mv	a0,s1
    800055b4:	fffff097          	auipc	ra,0xfffff
    800055b8:	858080e7          	jalr	-1960(ra) # 80003e0c <iunlockput>
  return ip;
    800055bc:	8ad2                	mv	s5,s4
    800055be:	b759                	j	80005544 <create+0x72>
    iunlockput(dp);
    800055c0:	8526                	mv	a0,s1
    800055c2:	fffff097          	auipc	ra,0xfffff
    800055c6:	84a080e7          	jalr	-1974(ra) # 80003e0c <iunlockput>
    return 0;
    800055ca:	8ad2                	mv	s5,s4
    800055cc:	bfa5                	j	80005544 <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800055ce:	004a2603          	lw	a2,4(s4)
    800055d2:	00003597          	auipc	a1,0x3
    800055d6:	15e58593          	add	a1,a1,350 # 80008730 <syscalls+0x2b8>
    800055da:	8552                	mv	a0,s4
    800055dc:	fffff097          	auipc	ra,0xfffff
    800055e0:	cc2080e7          	jalr	-830(ra) # 8000429e <dirlink>
    800055e4:	04054463          	bltz	a0,8000562c <create+0x15a>
    800055e8:	40d0                	lw	a2,4(s1)
    800055ea:	00003597          	auipc	a1,0x3
    800055ee:	14e58593          	add	a1,a1,334 # 80008738 <syscalls+0x2c0>
    800055f2:	8552                	mv	a0,s4
    800055f4:	fffff097          	auipc	ra,0xfffff
    800055f8:	caa080e7          	jalr	-854(ra) # 8000429e <dirlink>
    800055fc:	02054863          	bltz	a0,8000562c <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    80005600:	004a2603          	lw	a2,4(s4)
    80005604:	fb040593          	add	a1,s0,-80
    80005608:	8526                	mv	a0,s1
    8000560a:	fffff097          	auipc	ra,0xfffff
    8000560e:	c94080e7          	jalr	-876(ra) # 8000429e <dirlink>
    80005612:	00054d63          	bltz	a0,8000562c <create+0x15a>
    dp->nlink++;  // for ".."
    80005616:	04a4d783          	lhu	a5,74(s1)
    8000561a:	2785                	addw	a5,a5,1
    8000561c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005620:	8526                	mv	a0,s1
    80005622:	ffffe097          	auipc	ra,0xffffe
    80005626:	4bc080e7          	jalr	1212(ra) # 80003ade <iupdate>
    8000562a:	b761                	j	800055b2 <create+0xe0>
  ip->nlink = 0;
    8000562c:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005630:	8552                	mv	a0,s4
    80005632:	ffffe097          	auipc	ra,0xffffe
    80005636:	4ac080e7          	jalr	1196(ra) # 80003ade <iupdate>
  iunlockput(ip);
    8000563a:	8552                	mv	a0,s4
    8000563c:	ffffe097          	auipc	ra,0xffffe
    80005640:	7d0080e7          	jalr	2000(ra) # 80003e0c <iunlockput>
  iunlockput(dp);
    80005644:	8526                	mv	a0,s1
    80005646:	ffffe097          	auipc	ra,0xffffe
    8000564a:	7c6080e7          	jalr	1990(ra) # 80003e0c <iunlockput>
  return 0;
    8000564e:	bddd                	j	80005544 <create+0x72>
    return 0;
    80005650:	8aaa                	mv	s5,a0
    80005652:	bdcd                	j	80005544 <create+0x72>

0000000080005654 <sys_dup>:
{
    80005654:	7179                	add	sp,sp,-48
    80005656:	f406                	sd	ra,40(sp)
    80005658:	f022                	sd	s0,32(sp)
    8000565a:	ec26                	sd	s1,24(sp)
    8000565c:	e84a                	sd	s2,16(sp)
    8000565e:	1800                	add	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005660:	fd840613          	add	a2,s0,-40
    80005664:	4581                	li	a1,0
    80005666:	4501                	li	a0,0
    80005668:	00000097          	auipc	ra,0x0
    8000566c:	dc8080e7          	jalr	-568(ra) # 80005430 <argfd>
    return -1;
    80005670:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005672:	02054363          	bltz	a0,80005698 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005676:	fd843903          	ld	s2,-40(s0)
    8000567a:	854a                	mv	a0,s2
    8000567c:	00000097          	auipc	ra,0x0
    80005680:	e14080e7          	jalr	-492(ra) # 80005490 <fdalloc>
    80005684:	84aa                	mv	s1,a0
    return -1;
    80005686:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005688:	00054863          	bltz	a0,80005698 <sys_dup+0x44>
  filedup(f);
    8000568c:	854a                	mv	a0,s2
    8000568e:	fffff097          	auipc	ra,0xfffff
    80005692:	334080e7          	jalr	820(ra) # 800049c2 <filedup>
  return fd;
    80005696:	87a6                	mv	a5,s1
}
    80005698:	853e                	mv	a0,a5
    8000569a:	70a2                	ld	ra,40(sp)
    8000569c:	7402                	ld	s0,32(sp)
    8000569e:	64e2                	ld	s1,24(sp)
    800056a0:	6942                	ld	s2,16(sp)
    800056a2:	6145                	add	sp,sp,48
    800056a4:	8082                	ret

00000000800056a6 <sys_getreadcount>:
{
    800056a6:	1141                	add	sp,sp,-16
    800056a8:	e422                	sd	s0,8(sp)
    800056aa:	0800                	add	s0,sp,16
}
    800056ac:	00003517          	auipc	a0,0x3
    800056b0:	25852503          	lw	a0,600(a0) # 80008904 <readCount>
    800056b4:	6422                	ld	s0,8(sp)
    800056b6:	0141                	add	sp,sp,16
    800056b8:	8082                	ret

00000000800056ba <sys_read>:
{
    800056ba:	7179                	add	sp,sp,-48
    800056bc:	f406                	sd	ra,40(sp)
    800056be:	f022                	sd	s0,32(sp)
    800056c0:	1800                	add	s0,sp,48
  readCount++;
    800056c2:	00003717          	auipc	a4,0x3
    800056c6:	24270713          	add	a4,a4,578 # 80008904 <readCount>
    800056ca:	431c                	lw	a5,0(a4)
    800056cc:	2785                	addw	a5,a5,1
    800056ce:	c31c                	sw	a5,0(a4)
  argaddr(1, &p);
    800056d0:	fd840593          	add	a1,s0,-40
    800056d4:	4505                	li	a0,1
    800056d6:	ffffe097          	auipc	ra,0xffffe
    800056da:	8e8080e7          	jalr	-1816(ra) # 80002fbe <argaddr>
  argint(2, &n);
    800056de:	fe440593          	add	a1,s0,-28
    800056e2:	4509                	li	a0,2
    800056e4:	ffffe097          	auipc	ra,0xffffe
    800056e8:	8ba080e7          	jalr	-1862(ra) # 80002f9e <argint>
  if(argfd(0, 0, &f) < 0)
    800056ec:	fe840613          	add	a2,s0,-24
    800056f0:	4581                	li	a1,0
    800056f2:	4501                	li	a0,0
    800056f4:	00000097          	auipc	ra,0x0
    800056f8:	d3c080e7          	jalr	-708(ra) # 80005430 <argfd>
    800056fc:	87aa                	mv	a5,a0
    return -1;
    800056fe:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005700:	0007cc63          	bltz	a5,80005718 <sys_read+0x5e>
  return fileread(f, p, n);
    80005704:	fe442603          	lw	a2,-28(s0)
    80005708:	fd843583          	ld	a1,-40(s0)
    8000570c:	fe843503          	ld	a0,-24(s0)
    80005710:	fffff097          	auipc	ra,0xfffff
    80005714:	43e080e7          	jalr	1086(ra) # 80004b4e <fileread>
}
    80005718:	70a2                	ld	ra,40(sp)
    8000571a:	7402                	ld	s0,32(sp)
    8000571c:	6145                	add	sp,sp,48
    8000571e:	8082                	ret

0000000080005720 <sys_write>:
{
    80005720:	7179                	add	sp,sp,-48
    80005722:	f406                	sd	ra,40(sp)
    80005724:	f022                	sd	s0,32(sp)
    80005726:	1800                	add	s0,sp,48
  argaddr(1, &p);
    80005728:	fd840593          	add	a1,s0,-40
    8000572c:	4505                	li	a0,1
    8000572e:	ffffe097          	auipc	ra,0xffffe
    80005732:	890080e7          	jalr	-1904(ra) # 80002fbe <argaddr>
  argint(2, &n);
    80005736:	fe440593          	add	a1,s0,-28
    8000573a:	4509                	li	a0,2
    8000573c:	ffffe097          	auipc	ra,0xffffe
    80005740:	862080e7          	jalr	-1950(ra) # 80002f9e <argint>
  if(argfd(0, 0, &f) < 0)
    80005744:	fe840613          	add	a2,s0,-24
    80005748:	4581                	li	a1,0
    8000574a:	4501                	li	a0,0
    8000574c:	00000097          	auipc	ra,0x0
    80005750:	ce4080e7          	jalr	-796(ra) # 80005430 <argfd>
    80005754:	87aa                	mv	a5,a0
    return -1;
    80005756:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005758:	0007cc63          	bltz	a5,80005770 <sys_write+0x50>
  return filewrite(f, p, n);
    8000575c:	fe442603          	lw	a2,-28(s0)
    80005760:	fd843583          	ld	a1,-40(s0)
    80005764:	fe843503          	ld	a0,-24(s0)
    80005768:	fffff097          	auipc	ra,0xfffff
    8000576c:	4a8080e7          	jalr	1192(ra) # 80004c10 <filewrite>
}
    80005770:	70a2                	ld	ra,40(sp)
    80005772:	7402                	ld	s0,32(sp)
    80005774:	6145                	add	sp,sp,48
    80005776:	8082                	ret

0000000080005778 <sys_close>:
{
    80005778:	1101                	add	sp,sp,-32
    8000577a:	ec06                	sd	ra,24(sp)
    8000577c:	e822                	sd	s0,16(sp)
    8000577e:	1000                	add	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005780:	fe040613          	add	a2,s0,-32
    80005784:	fec40593          	add	a1,s0,-20
    80005788:	4501                	li	a0,0
    8000578a:	00000097          	auipc	ra,0x0
    8000578e:	ca6080e7          	jalr	-858(ra) # 80005430 <argfd>
    return -1;
    80005792:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005794:	02054463          	bltz	a0,800057bc <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005798:	ffffc097          	auipc	ra,0xffffc
    8000579c:	2aa080e7          	jalr	682(ra) # 80001a42 <myproc>
    800057a0:	fec42783          	lw	a5,-20(s0)
    800057a4:	07e9                	add	a5,a5,26
    800057a6:	078e                	sll	a5,a5,0x3
    800057a8:	953e                	add	a0,a0,a5
    800057aa:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800057ae:	fe043503          	ld	a0,-32(s0)
    800057b2:	fffff097          	auipc	ra,0xfffff
    800057b6:	262080e7          	jalr	610(ra) # 80004a14 <fileclose>
  return 0;
    800057ba:	4781                	li	a5,0
}
    800057bc:	853e                	mv	a0,a5
    800057be:	60e2                	ld	ra,24(sp)
    800057c0:	6442                	ld	s0,16(sp)
    800057c2:	6105                	add	sp,sp,32
    800057c4:	8082                	ret

00000000800057c6 <sys_fstat>:
{
    800057c6:	1101                	add	sp,sp,-32
    800057c8:	ec06                	sd	ra,24(sp)
    800057ca:	e822                	sd	s0,16(sp)
    800057cc:	1000                	add	s0,sp,32
  argaddr(1, &st);
    800057ce:	fe040593          	add	a1,s0,-32
    800057d2:	4505                	li	a0,1
    800057d4:	ffffd097          	auipc	ra,0xffffd
    800057d8:	7ea080e7          	jalr	2026(ra) # 80002fbe <argaddr>
  if(argfd(0, 0, &f) < 0)
    800057dc:	fe840613          	add	a2,s0,-24
    800057e0:	4581                	li	a1,0
    800057e2:	4501                	li	a0,0
    800057e4:	00000097          	auipc	ra,0x0
    800057e8:	c4c080e7          	jalr	-948(ra) # 80005430 <argfd>
    800057ec:	87aa                	mv	a5,a0
    return -1;
    800057ee:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800057f0:	0007ca63          	bltz	a5,80005804 <sys_fstat+0x3e>
  return filestat(f, st);
    800057f4:	fe043583          	ld	a1,-32(s0)
    800057f8:	fe843503          	ld	a0,-24(s0)
    800057fc:	fffff097          	auipc	ra,0xfffff
    80005800:	2e0080e7          	jalr	736(ra) # 80004adc <filestat>
}
    80005804:	60e2                	ld	ra,24(sp)
    80005806:	6442                	ld	s0,16(sp)
    80005808:	6105                	add	sp,sp,32
    8000580a:	8082                	ret

000000008000580c <sys_link>:
{
    8000580c:	7169                	add	sp,sp,-304
    8000580e:	f606                	sd	ra,296(sp)
    80005810:	f222                	sd	s0,288(sp)
    80005812:	ee26                	sd	s1,280(sp)
    80005814:	ea4a                	sd	s2,272(sp)
    80005816:	1a00                	add	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005818:	08000613          	li	a2,128
    8000581c:	ed040593          	add	a1,s0,-304
    80005820:	4501                	li	a0,0
    80005822:	ffffd097          	auipc	ra,0xffffd
    80005826:	7bc080e7          	jalr	1980(ra) # 80002fde <argstr>
    return -1;
    8000582a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000582c:	10054e63          	bltz	a0,80005948 <sys_link+0x13c>
    80005830:	08000613          	li	a2,128
    80005834:	f5040593          	add	a1,s0,-176
    80005838:	4505                	li	a0,1
    8000583a:	ffffd097          	auipc	ra,0xffffd
    8000583e:	7a4080e7          	jalr	1956(ra) # 80002fde <argstr>
    return -1;
    80005842:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005844:	10054263          	bltz	a0,80005948 <sys_link+0x13c>
  begin_op();
    80005848:	fffff097          	auipc	ra,0xfffff
    8000584c:	d08080e7          	jalr	-760(ra) # 80004550 <begin_op>
  if((ip = namei(old)) == 0){
    80005850:	ed040513          	add	a0,s0,-304
    80005854:	fffff097          	auipc	ra,0xfffff
    80005858:	afc080e7          	jalr	-1284(ra) # 80004350 <namei>
    8000585c:	84aa                	mv	s1,a0
    8000585e:	c551                	beqz	a0,800058ea <sys_link+0xde>
  ilock(ip);
    80005860:	ffffe097          	auipc	ra,0xffffe
    80005864:	34a080e7          	jalr	842(ra) # 80003baa <ilock>
  if(ip->type == T_DIR){
    80005868:	04449703          	lh	a4,68(s1)
    8000586c:	4785                	li	a5,1
    8000586e:	08f70463          	beq	a4,a5,800058f6 <sys_link+0xea>
  ip->nlink++;
    80005872:	04a4d783          	lhu	a5,74(s1)
    80005876:	2785                	addw	a5,a5,1
    80005878:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000587c:	8526                	mv	a0,s1
    8000587e:	ffffe097          	auipc	ra,0xffffe
    80005882:	260080e7          	jalr	608(ra) # 80003ade <iupdate>
  iunlock(ip);
    80005886:	8526                	mv	a0,s1
    80005888:	ffffe097          	auipc	ra,0xffffe
    8000588c:	3e4080e7          	jalr	996(ra) # 80003c6c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005890:	fd040593          	add	a1,s0,-48
    80005894:	f5040513          	add	a0,s0,-176
    80005898:	fffff097          	auipc	ra,0xfffff
    8000589c:	ad6080e7          	jalr	-1322(ra) # 8000436e <nameiparent>
    800058a0:	892a                	mv	s2,a0
    800058a2:	c935                	beqz	a0,80005916 <sys_link+0x10a>
  ilock(dp);
    800058a4:	ffffe097          	auipc	ra,0xffffe
    800058a8:	306080e7          	jalr	774(ra) # 80003baa <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800058ac:	00092703          	lw	a4,0(s2)
    800058b0:	409c                	lw	a5,0(s1)
    800058b2:	04f71d63          	bne	a4,a5,8000590c <sys_link+0x100>
    800058b6:	40d0                	lw	a2,4(s1)
    800058b8:	fd040593          	add	a1,s0,-48
    800058bc:	854a                	mv	a0,s2
    800058be:	fffff097          	auipc	ra,0xfffff
    800058c2:	9e0080e7          	jalr	-1568(ra) # 8000429e <dirlink>
    800058c6:	04054363          	bltz	a0,8000590c <sys_link+0x100>
  iunlockput(dp);
    800058ca:	854a                	mv	a0,s2
    800058cc:	ffffe097          	auipc	ra,0xffffe
    800058d0:	540080e7          	jalr	1344(ra) # 80003e0c <iunlockput>
  iput(ip);
    800058d4:	8526                	mv	a0,s1
    800058d6:	ffffe097          	auipc	ra,0xffffe
    800058da:	48e080e7          	jalr	1166(ra) # 80003d64 <iput>
  end_op();
    800058de:	fffff097          	auipc	ra,0xfffff
    800058e2:	cec080e7          	jalr	-788(ra) # 800045ca <end_op>
  return 0;
    800058e6:	4781                	li	a5,0
    800058e8:	a085                	j	80005948 <sys_link+0x13c>
    end_op();
    800058ea:	fffff097          	auipc	ra,0xfffff
    800058ee:	ce0080e7          	jalr	-800(ra) # 800045ca <end_op>
    return -1;
    800058f2:	57fd                	li	a5,-1
    800058f4:	a891                	j	80005948 <sys_link+0x13c>
    iunlockput(ip);
    800058f6:	8526                	mv	a0,s1
    800058f8:	ffffe097          	auipc	ra,0xffffe
    800058fc:	514080e7          	jalr	1300(ra) # 80003e0c <iunlockput>
    end_op();
    80005900:	fffff097          	auipc	ra,0xfffff
    80005904:	cca080e7          	jalr	-822(ra) # 800045ca <end_op>
    return -1;
    80005908:	57fd                	li	a5,-1
    8000590a:	a83d                	j	80005948 <sys_link+0x13c>
    iunlockput(dp);
    8000590c:	854a                	mv	a0,s2
    8000590e:	ffffe097          	auipc	ra,0xffffe
    80005912:	4fe080e7          	jalr	1278(ra) # 80003e0c <iunlockput>
  ilock(ip);
    80005916:	8526                	mv	a0,s1
    80005918:	ffffe097          	auipc	ra,0xffffe
    8000591c:	292080e7          	jalr	658(ra) # 80003baa <ilock>
  ip->nlink--;
    80005920:	04a4d783          	lhu	a5,74(s1)
    80005924:	37fd                	addw	a5,a5,-1
    80005926:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000592a:	8526                	mv	a0,s1
    8000592c:	ffffe097          	auipc	ra,0xffffe
    80005930:	1b2080e7          	jalr	434(ra) # 80003ade <iupdate>
  iunlockput(ip);
    80005934:	8526                	mv	a0,s1
    80005936:	ffffe097          	auipc	ra,0xffffe
    8000593a:	4d6080e7          	jalr	1238(ra) # 80003e0c <iunlockput>
  end_op();
    8000593e:	fffff097          	auipc	ra,0xfffff
    80005942:	c8c080e7          	jalr	-884(ra) # 800045ca <end_op>
  return -1;
    80005946:	57fd                	li	a5,-1
}
    80005948:	853e                	mv	a0,a5
    8000594a:	70b2                	ld	ra,296(sp)
    8000594c:	7412                	ld	s0,288(sp)
    8000594e:	64f2                	ld	s1,280(sp)
    80005950:	6952                	ld	s2,272(sp)
    80005952:	6155                	add	sp,sp,304
    80005954:	8082                	ret

0000000080005956 <sys_unlink>:
{
    80005956:	7151                	add	sp,sp,-240
    80005958:	f586                	sd	ra,232(sp)
    8000595a:	f1a2                	sd	s0,224(sp)
    8000595c:	eda6                	sd	s1,216(sp)
    8000595e:	e9ca                	sd	s2,208(sp)
    80005960:	e5ce                	sd	s3,200(sp)
    80005962:	1980                	add	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005964:	08000613          	li	a2,128
    80005968:	f3040593          	add	a1,s0,-208
    8000596c:	4501                	li	a0,0
    8000596e:	ffffd097          	auipc	ra,0xffffd
    80005972:	670080e7          	jalr	1648(ra) # 80002fde <argstr>
    80005976:	18054163          	bltz	a0,80005af8 <sys_unlink+0x1a2>
  begin_op();
    8000597a:	fffff097          	auipc	ra,0xfffff
    8000597e:	bd6080e7          	jalr	-1066(ra) # 80004550 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005982:	fb040593          	add	a1,s0,-80
    80005986:	f3040513          	add	a0,s0,-208
    8000598a:	fffff097          	auipc	ra,0xfffff
    8000598e:	9e4080e7          	jalr	-1564(ra) # 8000436e <nameiparent>
    80005992:	84aa                	mv	s1,a0
    80005994:	c979                	beqz	a0,80005a6a <sys_unlink+0x114>
  ilock(dp);
    80005996:	ffffe097          	auipc	ra,0xffffe
    8000599a:	214080e7          	jalr	532(ra) # 80003baa <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000599e:	00003597          	auipc	a1,0x3
    800059a2:	d9258593          	add	a1,a1,-622 # 80008730 <syscalls+0x2b8>
    800059a6:	fb040513          	add	a0,s0,-80
    800059aa:	ffffe097          	auipc	ra,0xffffe
    800059ae:	6ca080e7          	jalr	1738(ra) # 80004074 <namecmp>
    800059b2:	14050a63          	beqz	a0,80005b06 <sys_unlink+0x1b0>
    800059b6:	00003597          	auipc	a1,0x3
    800059ba:	d8258593          	add	a1,a1,-638 # 80008738 <syscalls+0x2c0>
    800059be:	fb040513          	add	a0,s0,-80
    800059c2:	ffffe097          	auipc	ra,0xffffe
    800059c6:	6b2080e7          	jalr	1714(ra) # 80004074 <namecmp>
    800059ca:	12050e63          	beqz	a0,80005b06 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800059ce:	f2c40613          	add	a2,s0,-212
    800059d2:	fb040593          	add	a1,s0,-80
    800059d6:	8526                	mv	a0,s1
    800059d8:	ffffe097          	auipc	ra,0xffffe
    800059dc:	6b6080e7          	jalr	1718(ra) # 8000408e <dirlookup>
    800059e0:	892a                	mv	s2,a0
    800059e2:	12050263          	beqz	a0,80005b06 <sys_unlink+0x1b0>
  ilock(ip);
    800059e6:	ffffe097          	auipc	ra,0xffffe
    800059ea:	1c4080e7          	jalr	452(ra) # 80003baa <ilock>
  if(ip->nlink < 1)
    800059ee:	04a91783          	lh	a5,74(s2)
    800059f2:	08f05263          	blez	a5,80005a76 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800059f6:	04491703          	lh	a4,68(s2)
    800059fa:	4785                	li	a5,1
    800059fc:	08f70563          	beq	a4,a5,80005a86 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005a00:	4641                	li	a2,16
    80005a02:	4581                	li	a1,0
    80005a04:	fc040513          	add	a0,s0,-64
    80005a08:	ffffb097          	auipc	ra,0xffffb
    80005a0c:	390080e7          	jalr	912(ra) # 80000d98 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a10:	4741                	li	a4,16
    80005a12:	f2c42683          	lw	a3,-212(s0)
    80005a16:	fc040613          	add	a2,s0,-64
    80005a1a:	4581                	li	a1,0
    80005a1c:	8526                	mv	a0,s1
    80005a1e:	ffffe097          	auipc	ra,0xffffe
    80005a22:	538080e7          	jalr	1336(ra) # 80003f56 <writei>
    80005a26:	47c1                	li	a5,16
    80005a28:	0af51563          	bne	a0,a5,80005ad2 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005a2c:	04491703          	lh	a4,68(s2)
    80005a30:	4785                	li	a5,1
    80005a32:	0af70863          	beq	a4,a5,80005ae2 <sys_unlink+0x18c>
  iunlockput(dp);
    80005a36:	8526                	mv	a0,s1
    80005a38:	ffffe097          	auipc	ra,0xffffe
    80005a3c:	3d4080e7          	jalr	980(ra) # 80003e0c <iunlockput>
  ip->nlink--;
    80005a40:	04a95783          	lhu	a5,74(s2)
    80005a44:	37fd                	addw	a5,a5,-1
    80005a46:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005a4a:	854a                	mv	a0,s2
    80005a4c:	ffffe097          	auipc	ra,0xffffe
    80005a50:	092080e7          	jalr	146(ra) # 80003ade <iupdate>
  iunlockput(ip);
    80005a54:	854a                	mv	a0,s2
    80005a56:	ffffe097          	auipc	ra,0xffffe
    80005a5a:	3b6080e7          	jalr	950(ra) # 80003e0c <iunlockput>
  end_op();
    80005a5e:	fffff097          	auipc	ra,0xfffff
    80005a62:	b6c080e7          	jalr	-1172(ra) # 800045ca <end_op>
  return 0;
    80005a66:	4501                	li	a0,0
    80005a68:	a84d                	j	80005b1a <sys_unlink+0x1c4>
    end_op();
    80005a6a:	fffff097          	auipc	ra,0xfffff
    80005a6e:	b60080e7          	jalr	-1184(ra) # 800045ca <end_op>
    return -1;
    80005a72:	557d                	li	a0,-1
    80005a74:	a05d                	j	80005b1a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005a76:	00003517          	auipc	a0,0x3
    80005a7a:	cca50513          	add	a0,a0,-822 # 80008740 <syscalls+0x2c8>
    80005a7e:	ffffb097          	auipc	ra,0xffffb
    80005a82:	abe080e7          	jalr	-1346(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a86:	04c92703          	lw	a4,76(s2)
    80005a8a:	02000793          	li	a5,32
    80005a8e:	f6e7f9e3          	bgeu	a5,a4,80005a00 <sys_unlink+0xaa>
    80005a92:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a96:	4741                	li	a4,16
    80005a98:	86ce                	mv	a3,s3
    80005a9a:	f1840613          	add	a2,s0,-232
    80005a9e:	4581                	li	a1,0
    80005aa0:	854a                	mv	a0,s2
    80005aa2:	ffffe097          	auipc	ra,0xffffe
    80005aa6:	3bc080e7          	jalr	956(ra) # 80003e5e <readi>
    80005aaa:	47c1                	li	a5,16
    80005aac:	00f51b63          	bne	a0,a5,80005ac2 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005ab0:	f1845783          	lhu	a5,-232(s0)
    80005ab4:	e7a1                	bnez	a5,80005afc <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ab6:	29c1                	addw	s3,s3,16
    80005ab8:	04c92783          	lw	a5,76(s2)
    80005abc:	fcf9ede3          	bltu	s3,a5,80005a96 <sys_unlink+0x140>
    80005ac0:	b781                	j	80005a00 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005ac2:	00003517          	auipc	a0,0x3
    80005ac6:	c9650513          	add	a0,a0,-874 # 80008758 <syscalls+0x2e0>
    80005aca:	ffffb097          	auipc	ra,0xffffb
    80005ace:	a72080e7          	jalr	-1422(ra) # 8000053c <panic>
    panic("unlink: writei");
    80005ad2:	00003517          	auipc	a0,0x3
    80005ad6:	c9e50513          	add	a0,a0,-866 # 80008770 <syscalls+0x2f8>
    80005ada:	ffffb097          	auipc	ra,0xffffb
    80005ade:	a62080e7          	jalr	-1438(ra) # 8000053c <panic>
    dp->nlink--;
    80005ae2:	04a4d783          	lhu	a5,74(s1)
    80005ae6:	37fd                	addw	a5,a5,-1
    80005ae8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005aec:	8526                	mv	a0,s1
    80005aee:	ffffe097          	auipc	ra,0xffffe
    80005af2:	ff0080e7          	jalr	-16(ra) # 80003ade <iupdate>
    80005af6:	b781                	j	80005a36 <sys_unlink+0xe0>
    return -1;
    80005af8:	557d                	li	a0,-1
    80005afa:	a005                	j	80005b1a <sys_unlink+0x1c4>
    iunlockput(ip);
    80005afc:	854a                	mv	a0,s2
    80005afe:	ffffe097          	auipc	ra,0xffffe
    80005b02:	30e080e7          	jalr	782(ra) # 80003e0c <iunlockput>
  iunlockput(dp);
    80005b06:	8526                	mv	a0,s1
    80005b08:	ffffe097          	auipc	ra,0xffffe
    80005b0c:	304080e7          	jalr	772(ra) # 80003e0c <iunlockput>
  end_op();
    80005b10:	fffff097          	auipc	ra,0xfffff
    80005b14:	aba080e7          	jalr	-1350(ra) # 800045ca <end_op>
  return -1;
    80005b18:	557d                	li	a0,-1
}
    80005b1a:	70ae                	ld	ra,232(sp)
    80005b1c:	740e                	ld	s0,224(sp)
    80005b1e:	64ee                	ld	s1,216(sp)
    80005b20:	694e                	ld	s2,208(sp)
    80005b22:	69ae                	ld	s3,200(sp)
    80005b24:	616d                	add	sp,sp,240
    80005b26:	8082                	ret

0000000080005b28 <sys_open>:

uint64
sys_open(void)
{
    80005b28:	7131                	add	sp,sp,-192
    80005b2a:	fd06                	sd	ra,184(sp)
    80005b2c:	f922                	sd	s0,176(sp)
    80005b2e:	f526                	sd	s1,168(sp)
    80005b30:	f14a                	sd	s2,160(sp)
    80005b32:	ed4e                	sd	s3,152(sp)
    80005b34:	0180                	add	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005b36:	f4c40593          	add	a1,s0,-180
    80005b3a:	4505                	li	a0,1
    80005b3c:	ffffd097          	auipc	ra,0xffffd
    80005b40:	462080e7          	jalr	1122(ra) # 80002f9e <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005b44:	08000613          	li	a2,128
    80005b48:	f5040593          	add	a1,s0,-176
    80005b4c:	4501                	li	a0,0
    80005b4e:	ffffd097          	auipc	ra,0xffffd
    80005b52:	490080e7          	jalr	1168(ra) # 80002fde <argstr>
    80005b56:	87aa                	mv	a5,a0
    return -1;
    80005b58:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005b5a:	0a07c863          	bltz	a5,80005c0a <sys_open+0xe2>

  begin_op();
    80005b5e:	fffff097          	auipc	ra,0xfffff
    80005b62:	9f2080e7          	jalr	-1550(ra) # 80004550 <begin_op>

  if(omode & O_CREATE){
    80005b66:	f4c42783          	lw	a5,-180(s0)
    80005b6a:	2007f793          	and	a5,a5,512
    80005b6e:	cbdd                	beqz	a5,80005c24 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    80005b70:	4681                	li	a3,0
    80005b72:	4601                	li	a2,0
    80005b74:	4589                	li	a1,2
    80005b76:	f5040513          	add	a0,s0,-176
    80005b7a:	00000097          	auipc	ra,0x0
    80005b7e:	958080e7          	jalr	-1704(ra) # 800054d2 <create>
    80005b82:	84aa                	mv	s1,a0
    if(ip == 0){
    80005b84:	c951                	beqz	a0,80005c18 <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005b86:	04449703          	lh	a4,68(s1)
    80005b8a:	478d                	li	a5,3
    80005b8c:	00f71763          	bne	a4,a5,80005b9a <sys_open+0x72>
    80005b90:	0464d703          	lhu	a4,70(s1)
    80005b94:	47a5                	li	a5,9
    80005b96:	0ce7ec63          	bltu	a5,a4,80005c6e <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005b9a:	fffff097          	auipc	ra,0xfffff
    80005b9e:	dbe080e7          	jalr	-578(ra) # 80004958 <filealloc>
    80005ba2:	892a                	mv	s2,a0
    80005ba4:	c56d                	beqz	a0,80005c8e <sys_open+0x166>
    80005ba6:	00000097          	auipc	ra,0x0
    80005baa:	8ea080e7          	jalr	-1814(ra) # 80005490 <fdalloc>
    80005bae:	89aa                	mv	s3,a0
    80005bb0:	0c054a63          	bltz	a0,80005c84 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005bb4:	04449703          	lh	a4,68(s1)
    80005bb8:	478d                	li	a5,3
    80005bba:	0ef70563          	beq	a4,a5,80005ca4 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005bbe:	4789                	li	a5,2
    80005bc0:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005bc4:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005bc8:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005bcc:	f4c42783          	lw	a5,-180(s0)
    80005bd0:	0017c713          	xor	a4,a5,1
    80005bd4:	8b05                	and	a4,a4,1
    80005bd6:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005bda:	0037f713          	and	a4,a5,3
    80005bde:	00e03733          	snez	a4,a4
    80005be2:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005be6:	4007f793          	and	a5,a5,1024
    80005bea:	c791                	beqz	a5,80005bf6 <sys_open+0xce>
    80005bec:	04449703          	lh	a4,68(s1)
    80005bf0:	4789                	li	a5,2
    80005bf2:	0cf70063          	beq	a4,a5,80005cb2 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80005bf6:	8526                	mv	a0,s1
    80005bf8:	ffffe097          	auipc	ra,0xffffe
    80005bfc:	074080e7          	jalr	116(ra) # 80003c6c <iunlock>
  end_op();
    80005c00:	fffff097          	auipc	ra,0xfffff
    80005c04:	9ca080e7          	jalr	-1590(ra) # 800045ca <end_op>

  return fd;
    80005c08:	854e                	mv	a0,s3
}
    80005c0a:	70ea                	ld	ra,184(sp)
    80005c0c:	744a                	ld	s0,176(sp)
    80005c0e:	74aa                	ld	s1,168(sp)
    80005c10:	790a                	ld	s2,160(sp)
    80005c12:	69ea                	ld	s3,152(sp)
    80005c14:	6129                	add	sp,sp,192
    80005c16:	8082                	ret
      end_op();
    80005c18:	fffff097          	auipc	ra,0xfffff
    80005c1c:	9b2080e7          	jalr	-1614(ra) # 800045ca <end_op>
      return -1;
    80005c20:	557d                	li	a0,-1
    80005c22:	b7e5                	j	80005c0a <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005c24:	f5040513          	add	a0,s0,-176
    80005c28:	ffffe097          	auipc	ra,0xffffe
    80005c2c:	728080e7          	jalr	1832(ra) # 80004350 <namei>
    80005c30:	84aa                	mv	s1,a0
    80005c32:	c905                	beqz	a0,80005c62 <sys_open+0x13a>
    ilock(ip);
    80005c34:	ffffe097          	auipc	ra,0xffffe
    80005c38:	f76080e7          	jalr	-138(ra) # 80003baa <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005c3c:	04449703          	lh	a4,68(s1)
    80005c40:	4785                	li	a5,1
    80005c42:	f4f712e3          	bne	a4,a5,80005b86 <sys_open+0x5e>
    80005c46:	f4c42783          	lw	a5,-180(s0)
    80005c4a:	dba1                	beqz	a5,80005b9a <sys_open+0x72>
      iunlockput(ip);
    80005c4c:	8526                	mv	a0,s1
    80005c4e:	ffffe097          	auipc	ra,0xffffe
    80005c52:	1be080e7          	jalr	446(ra) # 80003e0c <iunlockput>
      end_op();
    80005c56:	fffff097          	auipc	ra,0xfffff
    80005c5a:	974080e7          	jalr	-1676(ra) # 800045ca <end_op>
      return -1;
    80005c5e:	557d                	li	a0,-1
    80005c60:	b76d                	j	80005c0a <sys_open+0xe2>
      end_op();
    80005c62:	fffff097          	auipc	ra,0xfffff
    80005c66:	968080e7          	jalr	-1688(ra) # 800045ca <end_op>
      return -1;
    80005c6a:	557d                	li	a0,-1
    80005c6c:	bf79                	j	80005c0a <sys_open+0xe2>
    iunlockput(ip);
    80005c6e:	8526                	mv	a0,s1
    80005c70:	ffffe097          	auipc	ra,0xffffe
    80005c74:	19c080e7          	jalr	412(ra) # 80003e0c <iunlockput>
    end_op();
    80005c78:	fffff097          	auipc	ra,0xfffff
    80005c7c:	952080e7          	jalr	-1710(ra) # 800045ca <end_op>
    return -1;
    80005c80:	557d                	li	a0,-1
    80005c82:	b761                	j	80005c0a <sys_open+0xe2>
      fileclose(f);
    80005c84:	854a                	mv	a0,s2
    80005c86:	fffff097          	auipc	ra,0xfffff
    80005c8a:	d8e080e7          	jalr	-626(ra) # 80004a14 <fileclose>
    iunlockput(ip);
    80005c8e:	8526                	mv	a0,s1
    80005c90:	ffffe097          	auipc	ra,0xffffe
    80005c94:	17c080e7          	jalr	380(ra) # 80003e0c <iunlockput>
    end_op();
    80005c98:	fffff097          	auipc	ra,0xfffff
    80005c9c:	932080e7          	jalr	-1742(ra) # 800045ca <end_op>
    return -1;
    80005ca0:	557d                	li	a0,-1
    80005ca2:	b7a5                	j	80005c0a <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005ca4:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005ca8:	04649783          	lh	a5,70(s1)
    80005cac:	02f91223          	sh	a5,36(s2)
    80005cb0:	bf21                	j	80005bc8 <sys_open+0xa0>
    itrunc(ip);
    80005cb2:	8526                	mv	a0,s1
    80005cb4:	ffffe097          	auipc	ra,0xffffe
    80005cb8:	004080e7          	jalr	4(ra) # 80003cb8 <itrunc>
    80005cbc:	bf2d                	j	80005bf6 <sys_open+0xce>

0000000080005cbe <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005cbe:	7175                	add	sp,sp,-144
    80005cc0:	e506                	sd	ra,136(sp)
    80005cc2:	e122                	sd	s0,128(sp)
    80005cc4:	0900                	add	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005cc6:	fffff097          	auipc	ra,0xfffff
    80005cca:	88a080e7          	jalr	-1910(ra) # 80004550 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005cce:	08000613          	li	a2,128
    80005cd2:	f7040593          	add	a1,s0,-144
    80005cd6:	4501                	li	a0,0
    80005cd8:	ffffd097          	auipc	ra,0xffffd
    80005cdc:	306080e7          	jalr	774(ra) # 80002fde <argstr>
    80005ce0:	02054963          	bltz	a0,80005d12 <sys_mkdir+0x54>
    80005ce4:	4681                	li	a3,0
    80005ce6:	4601                	li	a2,0
    80005ce8:	4585                	li	a1,1
    80005cea:	f7040513          	add	a0,s0,-144
    80005cee:	fffff097          	auipc	ra,0xfffff
    80005cf2:	7e4080e7          	jalr	2020(ra) # 800054d2 <create>
    80005cf6:	cd11                	beqz	a0,80005d12 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005cf8:	ffffe097          	auipc	ra,0xffffe
    80005cfc:	114080e7          	jalr	276(ra) # 80003e0c <iunlockput>
  end_op();
    80005d00:	fffff097          	auipc	ra,0xfffff
    80005d04:	8ca080e7          	jalr	-1846(ra) # 800045ca <end_op>
  return 0;
    80005d08:	4501                	li	a0,0
}
    80005d0a:	60aa                	ld	ra,136(sp)
    80005d0c:	640a                	ld	s0,128(sp)
    80005d0e:	6149                	add	sp,sp,144
    80005d10:	8082                	ret
    end_op();
    80005d12:	fffff097          	auipc	ra,0xfffff
    80005d16:	8b8080e7          	jalr	-1864(ra) # 800045ca <end_op>
    return -1;
    80005d1a:	557d                	li	a0,-1
    80005d1c:	b7fd                	j	80005d0a <sys_mkdir+0x4c>

0000000080005d1e <sys_mknod>:

uint64
sys_mknod(void)
{
    80005d1e:	7135                	add	sp,sp,-160
    80005d20:	ed06                	sd	ra,152(sp)
    80005d22:	e922                	sd	s0,144(sp)
    80005d24:	1100                	add	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005d26:	fffff097          	auipc	ra,0xfffff
    80005d2a:	82a080e7          	jalr	-2006(ra) # 80004550 <begin_op>
  argint(1, &major);
    80005d2e:	f6c40593          	add	a1,s0,-148
    80005d32:	4505                	li	a0,1
    80005d34:	ffffd097          	auipc	ra,0xffffd
    80005d38:	26a080e7          	jalr	618(ra) # 80002f9e <argint>
  argint(2, &minor);
    80005d3c:	f6840593          	add	a1,s0,-152
    80005d40:	4509                	li	a0,2
    80005d42:	ffffd097          	auipc	ra,0xffffd
    80005d46:	25c080e7          	jalr	604(ra) # 80002f9e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d4a:	08000613          	li	a2,128
    80005d4e:	f7040593          	add	a1,s0,-144
    80005d52:	4501                	li	a0,0
    80005d54:	ffffd097          	auipc	ra,0xffffd
    80005d58:	28a080e7          	jalr	650(ra) # 80002fde <argstr>
    80005d5c:	02054b63          	bltz	a0,80005d92 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005d60:	f6841683          	lh	a3,-152(s0)
    80005d64:	f6c41603          	lh	a2,-148(s0)
    80005d68:	458d                	li	a1,3
    80005d6a:	f7040513          	add	a0,s0,-144
    80005d6e:	fffff097          	auipc	ra,0xfffff
    80005d72:	764080e7          	jalr	1892(ra) # 800054d2 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d76:	cd11                	beqz	a0,80005d92 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d78:	ffffe097          	auipc	ra,0xffffe
    80005d7c:	094080e7          	jalr	148(ra) # 80003e0c <iunlockput>
  end_op();
    80005d80:	fffff097          	auipc	ra,0xfffff
    80005d84:	84a080e7          	jalr	-1974(ra) # 800045ca <end_op>
  return 0;
    80005d88:	4501                	li	a0,0
}
    80005d8a:	60ea                	ld	ra,152(sp)
    80005d8c:	644a                	ld	s0,144(sp)
    80005d8e:	610d                	add	sp,sp,160
    80005d90:	8082                	ret
    end_op();
    80005d92:	fffff097          	auipc	ra,0xfffff
    80005d96:	838080e7          	jalr	-1992(ra) # 800045ca <end_op>
    return -1;
    80005d9a:	557d                	li	a0,-1
    80005d9c:	b7fd                	j	80005d8a <sys_mknod+0x6c>

0000000080005d9e <sys_chdir>:

uint64
sys_chdir(void)
{
    80005d9e:	7135                	add	sp,sp,-160
    80005da0:	ed06                	sd	ra,152(sp)
    80005da2:	e922                	sd	s0,144(sp)
    80005da4:	e526                	sd	s1,136(sp)
    80005da6:	e14a                	sd	s2,128(sp)
    80005da8:	1100                	add	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005daa:	ffffc097          	auipc	ra,0xffffc
    80005dae:	c98080e7          	jalr	-872(ra) # 80001a42 <myproc>
    80005db2:	892a                	mv	s2,a0
  
  begin_op();
    80005db4:	ffffe097          	auipc	ra,0xffffe
    80005db8:	79c080e7          	jalr	1948(ra) # 80004550 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005dbc:	08000613          	li	a2,128
    80005dc0:	f6040593          	add	a1,s0,-160
    80005dc4:	4501                	li	a0,0
    80005dc6:	ffffd097          	auipc	ra,0xffffd
    80005dca:	218080e7          	jalr	536(ra) # 80002fde <argstr>
    80005dce:	04054b63          	bltz	a0,80005e24 <sys_chdir+0x86>
    80005dd2:	f6040513          	add	a0,s0,-160
    80005dd6:	ffffe097          	auipc	ra,0xffffe
    80005dda:	57a080e7          	jalr	1402(ra) # 80004350 <namei>
    80005dde:	84aa                	mv	s1,a0
    80005de0:	c131                	beqz	a0,80005e24 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005de2:	ffffe097          	auipc	ra,0xffffe
    80005de6:	dc8080e7          	jalr	-568(ra) # 80003baa <ilock>
  if(ip->type != T_DIR){
    80005dea:	04449703          	lh	a4,68(s1)
    80005dee:	4785                	li	a5,1
    80005df0:	04f71063          	bne	a4,a5,80005e30 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005df4:	8526                	mv	a0,s1
    80005df6:	ffffe097          	auipc	ra,0xffffe
    80005dfa:	e76080e7          	jalr	-394(ra) # 80003c6c <iunlock>
  iput(p->cwd);
    80005dfe:	15093503          	ld	a0,336(s2)
    80005e02:	ffffe097          	auipc	ra,0xffffe
    80005e06:	f62080e7          	jalr	-158(ra) # 80003d64 <iput>
  end_op();
    80005e0a:	ffffe097          	auipc	ra,0xffffe
    80005e0e:	7c0080e7          	jalr	1984(ra) # 800045ca <end_op>
  p->cwd = ip;
    80005e12:	14993823          	sd	s1,336(s2)
  return 0;
    80005e16:	4501                	li	a0,0
}
    80005e18:	60ea                	ld	ra,152(sp)
    80005e1a:	644a                	ld	s0,144(sp)
    80005e1c:	64aa                	ld	s1,136(sp)
    80005e1e:	690a                	ld	s2,128(sp)
    80005e20:	610d                	add	sp,sp,160
    80005e22:	8082                	ret
    end_op();
    80005e24:	ffffe097          	auipc	ra,0xffffe
    80005e28:	7a6080e7          	jalr	1958(ra) # 800045ca <end_op>
    return -1;
    80005e2c:	557d                	li	a0,-1
    80005e2e:	b7ed                	j	80005e18 <sys_chdir+0x7a>
    iunlockput(ip);
    80005e30:	8526                	mv	a0,s1
    80005e32:	ffffe097          	auipc	ra,0xffffe
    80005e36:	fda080e7          	jalr	-38(ra) # 80003e0c <iunlockput>
    end_op();
    80005e3a:	ffffe097          	auipc	ra,0xffffe
    80005e3e:	790080e7          	jalr	1936(ra) # 800045ca <end_op>
    return -1;
    80005e42:	557d                	li	a0,-1
    80005e44:	bfd1                	j	80005e18 <sys_chdir+0x7a>

0000000080005e46 <sys_exec>:

uint64
sys_exec(void)
{
    80005e46:	7121                	add	sp,sp,-448
    80005e48:	ff06                	sd	ra,440(sp)
    80005e4a:	fb22                	sd	s0,432(sp)
    80005e4c:	f726                	sd	s1,424(sp)
    80005e4e:	f34a                	sd	s2,416(sp)
    80005e50:	ef4e                	sd	s3,408(sp)
    80005e52:	eb52                	sd	s4,400(sp)
    80005e54:	0380                	add	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005e56:	e4840593          	add	a1,s0,-440
    80005e5a:	4505                	li	a0,1
    80005e5c:	ffffd097          	auipc	ra,0xffffd
    80005e60:	162080e7          	jalr	354(ra) # 80002fbe <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005e64:	08000613          	li	a2,128
    80005e68:	f5040593          	add	a1,s0,-176
    80005e6c:	4501                	li	a0,0
    80005e6e:	ffffd097          	auipc	ra,0xffffd
    80005e72:	170080e7          	jalr	368(ra) # 80002fde <argstr>
    80005e76:	87aa                	mv	a5,a0
    return -1;
    80005e78:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005e7a:	0c07c263          	bltz	a5,80005f3e <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005e7e:	10000613          	li	a2,256
    80005e82:	4581                	li	a1,0
    80005e84:	e5040513          	add	a0,s0,-432
    80005e88:	ffffb097          	auipc	ra,0xffffb
    80005e8c:	f10080e7          	jalr	-240(ra) # 80000d98 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005e90:	e5040493          	add	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005e94:	89a6                	mv	s3,s1
    80005e96:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005e98:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005e9c:	00391513          	sll	a0,s2,0x3
    80005ea0:	e4040593          	add	a1,s0,-448
    80005ea4:	e4843783          	ld	a5,-440(s0)
    80005ea8:	953e                	add	a0,a0,a5
    80005eaa:	ffffd097          	auipc	ra,0xffffd
    80005eae:	056080e7          	jalr	86(ra) # 80002f00 <fetchaddr>
    80005eb2:	02054a63          	bltz	a0,80005ee6 <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80005eb6:	e4043783          	ld	a5,-448(s0)
    80005eba:	c3b9                	beqz	a5,80005f00 <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ebc:	ffffb097          	auipc	ra,0xffffb
    80005ec0:	c92080e7          	jalr	-878(ra) # 80000b4e <kalloc>
    80005ec4:	85aa                	mv	a1,a0
    80005ec6:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005eca:	cd11                	beqz	a0,80005ee6 <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ecc:	6605                	lui	a2,0x1
    80005ece:	e4043503          	ld	a0,-448(s0)
    80005ed2:	ffffd097          	auipc	ra,0xffffd
    80005ed6:	080080e7          	jalr	128(ra) # 80002f52 <fetchstr>
    80005eda:	00054663          	bltz	a0,80005ee6 <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005ede:	0905                	add	s2,s2,1
    80005ee0:	09a1                	add	s3,s3,8
    80005ee2:	fb491de3          	bne	s2,s4,80005e9c <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ee6:	f5040913          	add	s2,s0,-176
    80005eea:	6088                	ld	a0,0(s1)
    80005eec:	c921                	beqz	a0,80005f3c <sys_exec+0xf6>
    kfree(argv[i]);
    80005eee:	ffffb097          	auipc	ra,0xffffb
    80005ef2:	af6080e7          	jalr	-1290(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ef6:	04a1                	add	s1,s1,8
    80005ef8:	ff2499e3          	bne	s1,s2,80005eea <sys_exec+0xa4>
  return -1;
    80005efc:	557d                	li	a0,-1
    80005efe:	a081                	j	80005f3e <sys_exec+0xf8>
      argv[i] = 0;
    80005f00:	0009079b          	sext.w	a5,s2
    80005f04:	078e                	sll	a5,a5,0x3
    80005f06:	fd078793          	add	a5,a5,-48
    80005f0a:	97a2                	add	a5,a5,s0
    80005f0c:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005f10:	e5040593          	add	a1,s0,-432
    80005f14:	f5040513          	add	a0,s0,-176
    80005f18:	fffff097          	auipc	ra,0xfffff
    80005f1c:	172080e7          	jalr	370(ra) # 8000508a <exec>
    80005f20:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f22:	f5040993          	add	s3,s0,-176
    80005f26:	6088                	ld	a0,0(s1)
    80005f28:	c901                	beqz	a0,80005f38 <sys_exec+0xf2>
    kfree(argv[i]);
    80005f2a:	ffffb097          	auipc	ra,0xffffb
    80005f2e:	aba080e7          	jalr	-1350(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f32:	04a1                	add	s1,s1,8
    80005f34:	ff3499e3          	bne	s1,s3,80005f26 <sys_exec+0xe0>
  return ret;
    80005f38:	854a                	mv	a0,s2
    80005f3a:	a011                	j	80005f3e <sys_exec+0xf8>
  return -1;
    80005f3c:	557d                	li	a0,-1
}
    80005f3e:	70fa                	ld	ra,440(sp)
    80005f40:	745a                	ld	s0,432(sp)
    80005f42:	74ba                	ld	s1,424(sp)
    80005f44:	791a                	ld	s2,416(sp)
    80005f46:	69fa                	ld	s3,408(sp)
    80005f48:	6a5a                	ld	s4,400(sp)
    80005f4a:	6139                	add	sp,sp,448
    80005f4c:	8082                	ret

0000000080005f4e <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f4e:	7139                	add	sp,sp,-64
    80005f50:	fc06                	sd	ra,56(sp)
    80005f52:	f822                	sd	s0,48(sp)
    80005f54:	f426                	sd	s1,40(sp)
    80005f56:	0080                	add	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f58:	ffffc097          	auipc	ra,0xffffc
    80005f5c:	aea080e7          	jalr	-1302(ra) # 80001a42 <myproc>
    80005f60:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005f62:	fd840593          	add	a1,s0,-40
    80005f66:	4501                	li	a0,0
    80005f68:	ffffd097          	auipc	ra,0xffffd
    80005f6c:	056080e7          	jalr	86(ra) # 80002fbe <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005f70:	fc840593          	add	a1,s0,-56
    80005f74:	fd040513          	add	a0,s0,-48
    80005f78:	fffff097          	auipc	ra,0xfffff
    80005f7c:	dc8080e7          	jalr	-568(ra) # 80004d40 <pipealloc>
    return -1;
    80005f80:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005f82:	0c054463          	bltz	a0,8000604a <sys_pipe+0xfc>
  fd0 = -1;
    80005f86:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005f8a:	fd043503          	ld	a0,-48(s0)
    80005f8e:	fffff097          	auipc	ra,0xfffff
    80005f92:	502080e7          	jalr	1282(ra) # 80005490 <fdalloc>
    80005f96:	fca42223          	sw	a0,-60(s0)
    80005f9a:	08054b63          	bltz	a0,80006030 <sys_pipe+0xe2>
    80005f9e:	fc843503          	ld	a0,-56(s0)
    80005fa2:	fffff097          	auipc	ra,0xfffff
    80005fa6:	4ee080e7          	jalr	1262(ra) # 80005490 <fdalloc>
    80005faa:	fca42023          	sw	a0,-64(s0)
    80005fae:	06054863          	bltz	a0,8000601e <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fb2:	4691                	li	a3,4
    80005fb4:	fc440613          	add	a2,s0,-60
    80005fb8:	fd843583          	ld	a1,-40(s0)
    80005fbc:	68a8                	ld	a0,80(s1)
    80005fbe:	ffffb097          	auipc	ra,0xffffb
    80005fc2:	744080e7          	jalr	1860(ra) # 80001702 <copyout>
    80005fc6:	02054063          	bltz	a0,80005fe6 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005fca:	4691                	li	a3,4
    80005fcc:	fc040613          	add	a2,s0,-64
    80005fd0:	fd843583          	ld	a1,-40(s0)
    80005fd4:	0591                	add	a1,a1,4
    80005fd6:	68a8                	ld	a0,80(s1)
    80005fd8:	ffffb097          	auipc	ra,0xffffb
    80005fdc:	72a080e7          	jalr	1834(ra) # 80001702 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005fe0:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fe2:	06055463          	bgez	a0,8000604a <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005fe6:	fc442783          	lw	a5,-60(s0)
    80005fea:	07e9                	add	a5,a5,26
    80005fec:	078e                	sll	a5,a5,0x3
    80005fee:	97a6                	add	a5,a5,s1
    80005ff0:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005ff4:	fc042783          	lw	a5,-64(s0)
    80005ff8:	07e9                	add	a5,a5,26
    80005ffa:	078e                	sll	a5,a5,0x3
    80005ffc:	94be                	add	s1,s1,a5
    80005ffe:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006002:	fd043503          	ld	a0,-48(s0)
    80006006:	fffff097          	auipc	ra,0xfffff
    8000600a:	a0e080e7          	jalr	-1522(ra) # 80004a14 <fileclose>
    fileclose(wf);
    8000600e:	fc843503          	ld	a0,-56(s0)
    80006012:	fffff097          	auipc	ra,0xfffff
    80006016:	a02080e7          	jalr	-1534(ra) # 80004a14 <fileclose>
    return -1;
    8000601a:	57fd                	li	a5,-1
    8000601c:	a03d                	j	8000604a <sys_pipe+0xfc>
    if(fd0 >= 0)
    8000601e:	fc442783          	lw	a5,-60(s0)
    80006022:	0007c763          	bltz	a5,80006030 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80006026:	07e9                	add	a5,a5,26
    80006028:	078e                	sll	a5,a5,0x3
    8000602a:	97a6                	add	a5,a5,s1
    8000602c:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80006030:	fd043503          	ld	a0,-48(s0)
    80006034:	fffff097          	auipc	ra,0xfffff
    80006038:	9e0080e7          	jalr	-1568(ra) # 80004a14 <fileclose>
    fileclose(wf);
    8000603c:	fc843503          	ld	a0,-56(s0)
    80006040:	fffff097          	auipc	ra,0xfffff
    80006044:	9d4080e7          	jalr	-1580(ra) # 80004a14 <fileclose>
    return -1;
    80006048:	57fd                	li	a5,-1
}
    8000604a:	853e                	mv	a0,a5
    8000604c:	70e2                	ld	ra,56(sp)
    8000604e:	7442                	ld	s0,48(sp)
    80006050:	74a2                	ld	s1,40(sp)
    80006052:	6121                	add	sp,sp,64
    80006054:	8082                	ret
	...

0000000080006060 <kernelvec>:
    80006060:	7111                	add	sp,sp,-256
    80006062:	e006                	sd	ra,0(sp)
    80006064:	e40a                	sd	sp,8(sp)
    80006066:	e80e                	sd	gp,16(sp)
    80006068:	ec12                	sd	tp,24(sp)
    8000606a:	f016                	sd	t0,32(sp)
    8000606c:	f41a                	sd	t1,40(sp)
    8000606e:	f81e                	sd	t2,48(sp)
    80006070:	fc22                	sd	s0,56(sp)
    80006072:	e0a6                	sd	s1,64(sp)
    80006074:	e4aa                	sd	a0,72(sp)
    80006076:	e8ae                	sd	a1,80(sp)
    80006078:	ecb2                	sd	a2,88(sp)
    8000607a:	f0b6                	sd	a3,96(sp)
    8000607c:	f4ba                	sd	a4,104(sp)
    8000607e:	f8be                	sd	a5,112(sp)
    80006080:	fcc2                	sd	a6,120(sp)
    80006082:	e146                	sd	a7,128(sp)
    80006084:	e54a                	sd	s2,136(sp)
    80006086:	e94e                	sd	s3,144(sp)
    80006088:	ed52                	sd	s4,152(sp)
    8000608a:	f156                	sd	s5,160(sp)
    8000608c:	f55a                	sd	s6,168(sp)
    8000608e:	f95e                	sd	s7,176(sp)
    80006090:	fd62                	sd	s8,184(sp)
    80006092:	e1e6                	sd	s9,192(sp)
    80006094:	e5ea                	sd	s10,200(sp)
    80006096:	e9ee                	sd	s11,208(sp)
    80006098:	edf2                	sd	t3,216(sp)
    8000609a:	f1f6                	sd	t4,224(sp)
    8000609c:	f5fa                	sd	t5,232(sp)
    8000609e:	f9fe                	sd	t6,240(sp)
    800060a0:	d2dfc0ef          	jal	80002dcc <kerneltrap>
    800060a4:	6082                	ld	ra,0(sp)
    800060a6:	6122                	ld	sp,8(sp)
    800060a8:	61c2                	ld	gp,16(sp)
    800060aa:	7282                	ld	t0,32(sp)
    800060ac:	7322                	ld	t1,40(sp)
    800060ae:	73c2                	ld	t2,48(sp)
    800060b0:	7462                	ld	s0,56(sp)
    800060b2:	6486                	ld	s1,64(sp)
    800060b4:	6526                	ld	a0,72(sp)
    800060b6:	65c6                	ld	a1,80(sp)
    800060b8:	6666                	ld	a2,88(sp)
    800060ba:	7686                	ld	a3,96(sp)
    800060bc:	7726                	ld	a4,104(sp)
    800060be:	77c6                	ld	a5,112(sp)
    800060c0:	7866                	ld	a6,120(sp)
    800060c2:	688a                	ld	a7,128(sp)
    800060c4:	692a                	ld	s2,136(sp)
    800060c6:	69ca                	ld	s3,144(sp)
    800060c8:	6a6a                	ld	s4,152(sp)
    800060ca:	7a8a                	ld	s5,160(sp)
    800060cc:	7b2a                	ld	s6,168(sp)
    800060ce:	7bca                	ld	s7,176(sp)
    800060d0:	7c6a                	ld	s8,184(sp)
    800060d2:	6c8e                	ld	s9,192(sp)
    800060d4:	6d2e                	ld	s10,200(sp)
    800060d6:	6dce                	ld	s11,208(sp)
    800060d8:	6e6e                	ld	t3,216(sp)
    800060da:	7e8e                	ld	t4,224(sp)
    800060dc:	7f2e                	ld	t5,232(sp)
    800060de:	7fce                	ld	t6,240(sp)
    800060e0:	6111                	add	sp,sp,256
    800060e2:	10200073          	sret
    800060e6:	00000013          	nop
    800060ea:	00000013          	nop
    800060ee:	0001                	nop

00000000800060f0 <timervec>:
    800060f0:	34051573          	csrrw	a0,mscratch,a0
    800060f4:	e10c                	sd	a1,0(a0)
    800060f6:	e510                	sd	a2,8(a0)
    800060f8:	e914                	sd	a3,16(a0)
    800060fa:	6d0c                	ld	a1,24(a0)
    800060fc:	7110                	ld	a2,32(a0)
    800060fe:	6194                	ld	a3,0(a1)
    80006100:	96b2                	add	a3,a3,a2
    80006102:	e194                	sd	a3,0(a1)
    80006104:	4589                	li	a1,2
    80006106:	14459073          	csrw	sip,a1
    8000610a:	6914                	ld	a3,16(a0)
    8000610c:	6510                	ld	a2,8(a0)
    8000610e:	610c                	ld	a1,0(a0)
    80006110:	34051573          	csrrw	a0,mscratch,a0
    80006114:	30200073          	mret
	...

000000008000611a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000611a:	1141                	add	sp,sp,-16
    8000611c:	e422                	sd	s0,8(sp)
    8000611e:	0800                	add	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006120:	0c0007b7          	lui	a5,0xc000
    80006124:	4705                	li	a4,1
    80006126:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006128:	c3d8                	sw	a4,4(a5)
}
    8000612a:	6422                	ld	s0,8(sp)
    8000612c:	0141                	add	sp,sp,16
    8000612e:	8082                	ret

0000000080006130 <plicinithart>:

void
plicinithart(void)
{
    80006130:	1141                	add	sp,sp,-16
    80006132:	e406                	sd	ra,8(sp)
    80006134:	e022                	sd	s0,0(sp)
    80006136:	0800                	add	s0,sp,16
  int hart = cpuid();
    80006138:	ffffc097          	auipc	ra,0xffffc
    8000613c:	8de080e7          	jalr	-1826(ra) # 80001a16 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006140:	0085171b          	sllw	a4,a0,0x8
    80006144:	0c0027b7          	lui	a5,0xc002
    80006148:	97ba                	add	a5,a5,a4
    8000614a:	40200713          	li	a4,1026
    8000614e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006152:	00d5151b          	sllw	a0,a0,0xd
    80006156:	0c2017b7          	lui	a5,0xc201
    8000615a:	97aa                	add	a5,a5,a0
    8000615c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006160:	60a2                	ld	ra,8(sp)
    80006162:	6402                	ld	s0,0(sp)
    80006164:	0141                	add	sp,sp,16
    80006166:	8082                	ret

0000000080006168 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006168:	1141                	add	sp,sp,-16
    8000616a:	e406                	sd	ra,8(sp)
    8000616c:	e022                	sd	s0,0(sp)
    8000616e:	0800                	add	s0,sp,16
  int hart = cpuid();
    80006170:	ffffc097          	auipc	ra,0xffffc
    80006174:	8a6080e7          	jalr	-1882(ra) # 80001a16 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006178:	00d5151b          	sllw	a0,a0,0xd
    8000617c:	0c2017b7          	lui	a5,0xc201
    80006180:	97aa                	add	a5,a5,a0
  return irq;
}
    80006182:	43c8                	lw	a0,4(a5)
    80006184:	60a2                	ld	ra,8(sp)
    80006186:	6402                	ld	s0,0(sp)
    80006188:	0141                	add	sp,sp,16
    8000618a:	8082                	ret

000000008000618c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000618c:	1101                	add	sp,sp,-32
    8000618e:	ec06                	sd	ra,24(sp)
    80006190:	e822                	sd	s0,16(sp)
    80006192:	e426                	sd	s1,8(sp)
    80006194:	1000                	add	s0,sp,32
    80006196:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006198:	ffffc097          	auipc	ra,0xffffc
    8000619c:	87e080e7          	jalr	-1922(ra) # 80001a16 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800061a0:	00d5151b          	sllw	a0,a0,0xd
    800061a4:	0c2017b7          	lui	a5,0xc201
    800061a8:	97aa                	add	a5,a5,a0
    800061aa:	c3c4                	sw	s1,4(a5)
}
    800061ac:	60e2                	ld	ra,24(sp)
    800061ae:	6442                	ld	s0,16(sp)
    800061b0:	64a2                	ld	s1,8(sp)
    800061b2:	6105                	add	sp,sp,32
    800061b4:	8082                	ret

00000000800061b6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800061b6:	1141                	add	sp,sp,-16
    800061b8:	e406                	sd	ra,8(sp)
    800061ba:	e022                	sd	s0,0(sp)
    800061bc:	0800                	add	s0,sp,16
  if(i >= NUM)
    800061be:	479d                	li	a5,7
    800061c0:	04a7cc63          	blt	a5,a0,80006218 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800061c4:	0023c797          	auipc	a5,0x23c
    800061c8:	27c78793          	add	a5,a5,636 # 80242440 <disk>
    800061cc:	97aa                	add	a5,a5,a0
    800061ce:	0187c783          	lbu	a5,24(a5)
    800061d2:	ebb9                	bnez	a5,80006228 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800061d4:	00451693          	sll	a3,a0,0x4
    800061d8:	0023c797          	auipc	a5,0x23c
    800061dc:	26878793          	add	a5,a5,616 # 80242440 <disk>
    800061e0:	6398                	ld	a4,0(a5)
    800061e2:	9736                	add	a4,a4,a3
    800061e4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    800061e8:	6398                	ld	a4,0(a5)
    800061ea:	9736                	add	a4,a4,a3
    800061ec:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800061f0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800061f4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800061f8:	97aa                	add	a5,a5,a0
    800061fa:	4705                	li	a4,1
    800061fc:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006200:	0023c517          	auipc	a0,0x23c
    80006204:	25850513          	add	a0,a0,600 # 80242458 <disk+0x18>
    80006208:	ffffc097          	auipc	ra,0xffffc
    8000620c:	152080e7          	jalr	338(ra) # 8000235a <wakeup>
}
    80006210:	60a2                	ld	ra,8(sp)
    80006212:	6402                	ld	s0,0(sp)
    80006214:	0141                	add	sp,sp,16
    80006216:	8082                	ret
    panic("free_desc 1");
    80006218:	00002517          	auipc	a0,0x2
    8000621c:	56850513          	add	a0,a0,1384 # 80008780 <syscalls+0x308>
    80006220:	ffffa097          	auipc	ra,0xffffa
    80006224:	31c080e7          	jalr	796(ra) # 8000053c <panic>
    panic("free_desc 2");
    80006228:	00002517          	auipc	a0,0x2
    8000622c:	56850513          	add	a0,a0,1384 # 80008790 <syscalls+0x318>
    80006230:	ffffa097          	auipc	ra,0xffffa
    80006234:	30c080e7          	jalr	780(ra) # 8000053c <panic>

0000000080006238 <virtio_disk_init>:
{
    80006238:	1101                	add	sp,sp,-32
    8000623a:	ec06                	sd	ra,24(sp)
    8000623c:	e822                	sd	s0,16(sp)
    8000623e:	e426                	sd	s1,8(sp)
    80006240:	e04a                	sd	s2,0(sp)
    80006242:	1000                	add	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006244:	00002597          	auipc	a1,0x2
    80006248:	55c58593          	add	a1,a1,1372 # 800087a0 <syscalls+0x328>
    8000624c:	0023c517          	auipc	a0,0x23c
    80006250:	31c50513          	add	a0,a0,796 # 80242568 <disk+0x128>
    80006254:	ffffb097          	auipc	ra,0xffffb
    80006258:	9b8080e7          	jalr	-1608(ra) # 80000c0c <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000625c:	100017b7          	lui	a5,0x10001
    80006260:	4398                	lw	a4,0(a5)
    80006262:	2701                	sext.w	a4,a4
    80006264:	747277b7          	lui	a5,0x74727
    80006268:	97678793          	add	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000626c:	14f71b63          	bne	a4,a5,800063c2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006270:	100017b7          	lui	a5,0x10001
    80006274:	43dc                	lw	a5,4(a5)
    80006276:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006278:	4709                	li	a4,2
    8000627a:	14e79463          	bne	a5,a4,800063c2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000627e:	100017b7          	lui	a5,0x10001
    80006282:	479c                	lw	a5,8(a5)
    80006284:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006286:	12e79e63          	bne	a5,a4,800063c2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000628a:	100017b7          	lui	a5,0x10001
    8000628e:	47d8                	lw	a4,12(a5)
    80006290:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006292:	554d47b7          	lui	a5,0x554d4
    80006296:	55178793          	add	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000629a:	12f71463          	bne	a4,a5,800063c2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000629e:	100017b7          	lui	a5,0x10001
    800062a2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800062a6:	4705                	li	a4,1
    800062a8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062aa:	470d                	li	a4,3
    800062ac:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800062ae:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800062b0:	c7ffe6b7          	lui	a3,0xc7ffe
    800062b4:	75f68693          	add	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47dbc1df>
    800062b8:	8f75                	and	a4,a4,a3
    800062ba:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062bc:	472d                	li	a4,11
    800062be:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800062c0:	5bbc                	lw	a5,112(a5)
    800062c2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800062c6:	8ba1                	and	a5,a5,8
    800062c8:	10078563          	beqz	a5,800063d2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800062cc:	100017b7          	lui	a5,0x10001
    800062d0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800062d4:	43fc                	lw	a5,68(a5)
    800062d6:	2781                	sext.w	a5,a5
    800062d8:	10079563          	bnez	a5,800063e2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800062dc:	100017b7          	lui	a5,0x10001
    800062e0:	5bdc                	lw	a5,52(a5)
    800062e2:	2781                	sext.w	a5,a5
  if(max == 0)
    800062e4:	10078763          	beqz	a5,800063f2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    800062e8:	471d                	li	a4,7
    800062ea:	10f77c63          	bgeu	a4,a5,80006402 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    800062ee:	ffffb097          	auipc	ra,0xffffb
    800062f2:	860080e7          	jalr	-1952(ra) # 80000b4e <kalloc>
    800062f6:	0023c497          	auipc	s1,0x23c
    800062fa:	14a48493          	add	s1,s1,330 # 80242440 <disk>
    800062fe:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006300:	ffffb097          	auipc	ra,0xffffb
    80006304:	84e080e7          	jalr	-1970(ra) # 80000b4e <kalloc>
    80006308:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000630a:	ffffb097          	auipc	ra,0xffffb
    8000630e:	844080e7          	jalr	-1980(ra) # 80000b4e <kalloc>
    80006312:	87aa                	mv	a5,a0
    80006314:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006316:	6088                	ld	a0,0(s1)
    80006318:	cd6d                	beqz	a0,80006412 <virtio_disk_init+0x1da>
    8000631a:	0023c717          	auipc	a4,0x23c
    8000631e:	12e73703          	ld	a4,302(a4) # 80242448 <disk+0x8>
    80006322:	cb65                	beqz	a4,80006412 <virtio_disk_init+0x1da>
    80006324:	c7fd                	beqz	a5,80006412 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006326:	6605                	lui	a2,0x1
    80006328:	4581                	li	a1,0
    8000632a:	ffffb097          	auipc	ra,0xffffb
    8000632e:	a6e080e7          	jalr	-1426(ra) # 80000d98 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006332:	0023c497          	auipc	s1,0x23c
    80006336:	10e48493          	add	s1,s1,270 # 80242440 <disk>
    8000633a:	6605                	lui	a2,0x1
    8000633c:	4581                	li	a1,0
    8000633e:	6488                	ld	a0,8(s1)
    80006340:	ffffb097          	auipc	ra,0xffffb
    80006344:	a58080e7          	jalr	-1448(ra) # 80000d98 <memset>
  memset(disk.used, 0, PGSIZE);
    80006348:	6605                	lui	a2,0x1
    8000634a:	4581                	li	a1,0
    8000634c:	6888                	ld	a0,16(s1)
    8000634e:	ffffb097          	auipc	ra,0xffffb
    80006352:	a4a080e7          	jalr	-1462(ra) # 80000d98 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006356:	100017b7          	lui	a5,0x10001
    8000635a:	4721                	li	a4,8
    8000635c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000635e:	4098                	lw	a4,0(s1)
    80006360:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006364:	40d8                	lw	a4,4(s1)
    80006366:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000636a:	6498                	ld	a4,8(s1)
    8000636c:	0007069b          	sext.w	a3,a4
    80006370:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006374:	9701                	sra	a4,a4,0x20
    80006376:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000637a:	6898                	ld	a4,16(s1)
    8000637c:	0007069b          	sext.w	a3,a4
    80006380:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006384:	9701                	sra	a4,a4,0x20
    80006386:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000638a:	4705                	li	a4,1
    8000638c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000638e:	00e48c23          	sb	a4,24(s1)
    80006392:	00e48ca3          	sb	a4,25(s1)
    80006396:	00e48d23          	sb	a4,26(s1)
    8000639a:	00e48da3          	sb	a4,27(s1)
    8000639e:	00e48e23          	sb	a4,28(s1)
    800063a2:	00e48ea3          	sb	a4,29(s1)
    800063a6:	00e48f23          	sb	a4,30(s1)
    800063aa:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800063ae:	00496913          	or	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800063b2:	0727a823          	sw	s2,112(a5)
}
    800063b6:	60e2                	ld	ra,24(sp)
    800063b8:	6442                	ld	s0,16(sp)
    800063ba:	64a2                	ld	s1,8(sp)
    800063bc:	6902                	ld	s2,0(sp)
    800063be:	6105                	add	sp,sp,32
    800063c0:	8082                	ret
    panic("could not find virtio disk");
    800063c2:	00002517          	auipc	a0,0x2
    800063c6:	3ee50513          	add	a0,a0,1006 # 800087b0 <syscalls+0x338>
    800063ca:	ffffa097          	auipc	ra,0xffffa
    800063ce:	172080e7          	jalr	370(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    800063d2:	00002517          	auipc	a0,0x2
    800063d6:	3fe50513          	add	a0,a0,1022 # 800087d0 <syscalls+0x358>
    800063da:	ffffa097          	auipc	ra,0xffffa
    800063de:	162080e7          	jalr	354(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    800063e2:	00002517          	auipc	a0,0x2
    800063e6:	40e50513          	add	a0,a0,1038 # 800087f0 <syscalls+0x378>
    800063ea:	ffffa097          	auipc	ra,0xffffa
    800063ee:	152080e7          	jalr	338(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    800063f2:	00002517          	auipc	a0,0x2
    800063f6:	41e50513          	add	a0,a0,1054 # 80008810 <syscalls+0x398>
    800063fa:	ffffa097          	auipc	ra,0xffffa
    800063fe:	142080e7          	jalr	322(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    80006402:	00002517          	auipc	a0,0x2
    80006406:	42e50513          	add	a0,a0,1070 # 80008830 <syscalls+0x3b8>
    8000640a:	ffffa097          	auipc	ra,0xffffa
    8000640e:	132080e7          	jalr	306(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    80006412:	00002517          	auipc	a0,0x2
    80006416:	43e50513          	add	a0,a0,1086 # 80008850 <syscalls+0x3d8>
    8000641a:	ffffa097          	auipc	ra,0xffffa
    8000641e:	122080e7          	jalr	290(ra) # 8000053c <panic>

0000000080006422 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006422:	7159                	add	sp,sp,-112
    80006424:	f486                	sd	ra,104(sp)
    80006426:	f0a2                	sd	s0,96(sp)
    80006428:	eca6                	sd	s1,88(sp)
    8000642a:	e8ca                	sd	s2,80(sp)
    8000642c:	e4ce                	sd	s3,72(sp)
    8000642e:	e0d2                	sd	s4,64(sp)
    80006430:	fc56                	sd	s5,56(sp)
    80006432:	f85a                	sd	s6,48(sp)
    80006434:	f45e                	sd	s7,40(sp)
    80006436:	f062                	sd	s8,32(sp)
    80006438:	ec66                	sd	s9,24(sp)
    8000643a:	e86a                	sd	s10,16(sp)
    8000643c:	1880                	add	s0,sp,112
    8000643e:	8a2a                	mv	s4,a0
    80006440:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006442:	00c52c83          	lw	s9,12(a0)
    80006446:	001c9c9b          	sllw	s9,s9,0x1
    8000644a:	1c82                	sll	s9,s9,0x20
    8000644c:	020cdc93          	srl	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006450:	0023c517          	auipc	a0,0x23c
    80006454:	11850513          	add	a0,a0,280 # 80242568 <disk+0x128>
    80006458:	ffffb097          	auipc	ra,0xffffb
    8000645c:	844080e7          	jalr	-1980(ra) # 80000c9c <acquire>
  for(int i = 0; i < 3; i++){
    80006460:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80006462:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006464:	0023cb17          	auipc	s6,0x23c
    80006468:	fdcb0b13          	add	s6,s6,-36 # 80242440 <disk>
  for(int i = 0; i < 3; i++){
    8000646c:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000646e:	0023cc17          	auipc	s8,0x23c
    80006472:	0fac0c13          	add	s8,s8,250 # 80242568 <disk+0x128>
    80006476:	a095                	j	800064da <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80006478:	00fb0733          	add	a4,s6,a5
    8000647c:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006480:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80006482:	0207c563          	bltz	a5,800064ac <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80006486:	2605                	addw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80006488:	0591                	add	a1,a1,4
    8000648a:	05560d63          	beq	a2,s5,800064e4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    8000648e:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006490:	0023c717          	auipc	a4,0x23c
    80006494:	fb070713          	add	a4,a4,-80 # 80242440 <disk>
    80006498:	87ca                	mv	a5,s2
    if(disk.free[i]){
    8000649a:	01874683          	lbu	a3,24(a4)
    8000649e:	fee9                	bnez	a3,80006478 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    800064a0:	2785                	addw	a5,a5,1
    800064a2:	0705                	add	a4,a4,1
    800064a4:	fe979be3          	bne	a5,s1,8000649a <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    800064a8:	57fd                	li	a5,-1
    800064aa:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    800064ac:	00c05e63          	blez	a2,800064c8 <virtio_disk_rw+0xa6>
    800064b0:	060a                	sll	a2,a2,0x2
    800064b2:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    800064b6:	0009a503          	lw	a0,0(s3)
    800064ba:	00000097          	auipc	ra,0x0
    800064be:	cfc080e7          	jalr	-772(ra) # 800061b6 <free_desc>
      for(int j = 0; j < i; j++)
    800064c2:	0991                	add	s3,s3,4
    800064c4:	ffa999e3          	bne	s3,s10,800064b6 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800064c8:	85e2                	mv	a1,s8
    800064ca:	0023c517          	auipc	a0,0x23c
    800064ce:	f8e50513          	add	a0,a0,-114 # 80242458 <disk+0x18>
    800064d2:	ffffc097          	auipc	ra,0xffffc
    800064d6:	e24080e7          	jalr	-476(ra) # 800022f6 <sleep>
  for(int i = 0; i < 3; i++){
    800064da:	f9040993          	add	s3,s0,-112
{
    800064de:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    800064e0:	864a                	mv	a2,s2
    800064e2:	b775                	j	8000648e <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800064e4:	f9042503          	lw	a0,-112(s0)
    800064e8:	00a50713          	add	a4,a0,10
    800064ec:	0712                	sll	a4,a4,0x4

  if(write)
    800064ee:	0023c797          	auipc	a5,0x23c
    800064f2:	f5278793          	add	a5,a5,-174 # 80242440 <disk>
    800064f6:	00e786b3          	add	a3,a5,a4
    800064fa:	01703633          	snez	a2,s7
    800064fe:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006500:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006504:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006508:	f6070613          	add	a2,a4,-160
    8000650c:	6394                	ld	a3,0(a5)
    8000650e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006510:	00870593          	add	a1,a4,8
    80006514:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006516:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006518:	0007b803          	ld	a6,0(a5)
    8000651c:	9642                	add	a2,a2,a6
    8000651e:	46c1                	li	a3,16
    80006520:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006522:	4585                	li	a1,1
    80006524:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006528:	f9442683          	lw	a3,-108(s0)
    8000652c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006530:	0692                	sll	a3,a3,0x4
    80006532:	9836                	add	a6,a6,a3
    80006534:	058a0613          	add	a2,s4,88
    80006538:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000653c:	0007b803          	ld	a6,0(a5)
    80006540:	96c2                	add	a3,a3,a6
    80006542:	40000613          	li	a2,1024
    80006546:	c690                	sw	a2,8(a3)
  if(write)
    80006548:	001bb613          	seqz	a2,s7
    8000654c:	0016161b          	sllw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006550:	00166613          	or	a2,a2,1
    80006554:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006558:	f9842603          	lw	a2,-104(s0)
    8000655c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006560:	00250693          	add	a3,a0,2
    80006564:	0692                	sll	a3,a3,0x4
    80006566:	96be                	add	a3,a3,a5
    80006568:	58fd                	li	a7,-1
    8000656a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000656e:	0612                	sll	a2,a2,0x4
    80006570:	9832                	add	a6,a6,a2
    80006572:	f9070713          	add	a4,a4,-112
    80006576:	973e                	add	a4,a4,a5
    80006578:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000657c:	6398                	ld	a4,0(a5)
    8000657e:	9732                	add	a4,a4,a2
    80006580:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006582:	4609                	li	a2,2
    80006584:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006588:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000658c:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006590:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006594:	6794                	ld	a3,8(a5)
    80006596:	0026d703          	lhu	a4,2(a3)
    8000659a:	8b1d                	and	a4,a4,7
    8000659c:	0706                	sll	a4,a4,0x1
    8000659e:	96ba                	add	a3,a3,a4
    800065a0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    800065a4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800065a8:	6798                	ld	a4,8(a5)
    800065aa:	00275783          	lhu	a5,2(a4)
    800065ae:	2785                	addw	a5,a5,1
    800065b0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800065b4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800065b8:	100017b7          	lui	a5,0x10001
    800065bc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800065c0:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    800065c4:	0023c917          	auipc	s2,0x23c
    800065c8:	fa490913          	add	s2,s2,-92 # 80242568 <disk+0x128>
  while(b->disk == 1) {
    800065cc:	4485                	li	s1,1
    800065ce:	00b79c63          	bne	a5,a1,800065e6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800065d2:	85ca                	mv	a1,s2
    800065d4:	8552                	mv	a0,s4
    800065d6:	ffffc097          	auipc	ra,0xffffc
    800065da:	d20080e7          	jalr	-736(ra) # 800022f6 <sleep>
  while(b->disk == 1) {
    800065de:	004a2783          	lw	a5,4(s4)
    800065e2:	fe9788e3          	beq	a5,s1,800065d2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800065e6:	f9042903          	lw	s2,-112(s0)
    800065ea:	00290713          	add	a4,s2,2
    800065ee:	0712                	sll	a4,a4,0x4
    800065f0:	0023c797          	auipc	a5,0x23c
    800065f4:	e5078793          	add	a5,a5,-432 # 80242440 <disk>
    800065f8:	97ba                	add	a5,a5,a4
    800065fa:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800065fe:	0023c997          	auipc	s3,0x23c
    80006602:	e4298993          	add	s3,s3,-446 # 80242440 <disk>
    80006606:	00491713          	sll	a4,s2,0x4
    8000660a:	0009b783          	ld	a5,0(s3)
    8000660e:	97ba                	add	a5,a5,a4
    80006610:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006614:	854a                	mv	a0,s2
    80006616:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000661a:	00000097          	auipc	ra,0x0
    8000661e:	b9c080e7          	jalr	-1124(ra) # 800061b6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006622:	8885                	and	s1,s1,1
    80006624:	f0ed                	bnez	s1,80006606 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006626:	0023c517          	auipc	a0,0x23c
    8000662a:	f4250513          	add	a0,a0,-190 # 80242568 <disk+0x128>
    8000662e:	ffffa097          	auipc	ra,0xffffa
    80006632:	722080e7          	jalr	1826(ra) # 80000d50 <release>
}
    80006636:	70a6                	ld	ra,104(sp)
    80006638:	7406                	ld	s0,96(sp)
    8000663a:	64e6                	ld	s1,88(sp)
    8000663c:	6946                	ld	s2,80(sp)
    8000663e:	69a6                	ld	s3,72(sp)
    80006640:	6a06                	ld	s4,64(sp)
    80006642:	7ae2                	ld	s5,56(sp)
    80006644:	7b42                	ld	s6,48(sp)
    80006646:	7ba2                	ld	s7,40(sp)
    80006648:	7c02                	ld	s8,32(sp)
    8000664a:	6ce2                	ld	s9,24(sp)
    8000664c:	6d42                	ld	s10,16(sp)
    8000664e:	6165                	add	sp,sp,112
    80006650:	8082                	ret

0000000080006652 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006652:	1101                	add	sp,sp,-32
    80006654:	ec06                	sd	ra,24(sp)
    80006656:	e822                	sd	s0,16(sp)
    80006658:	e426                	sd	s1,8(sp)
    8000665a:	1000                	add	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000665c:	0023c497          	auipc	s1,0x23c
    80006660:	de448493          	add	s1,s1,-540 # 80242440 <disk>
    80006664:	0023c517          	auipc	a0,0x23c
    80006668:	f0450513          	add	a0,a0,-252 # 80242568 <disk+0x128>
    8000666c:	ffffa097          	auipc	ra,0xffffa
    80006670:	630080e7          	jalr	1584(ra) # 80000c9c <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006674:	10001737          	lui	a4,0x10001
    80006678:	533c                	lw	a5,96(a4)
    8000667a:	8b8d                	and	a5,a5,3
    8000667c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000667e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006682:	689c                	ld	a5,16(s1)
    80006684:	0204d703          	lhu	a4,32(s1)
    80006688:	0027d783          	lhu	a5,2(a5)
    8000668c:	04f70863          	beq	a4,a5,800066dc <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006690:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006694:	6898                	ld	a4,16(s1)
    80006696:	0204d783          	lhu	a5,32(s1)
    8000669a:	8b9d                	and	a5,a5,7
    8000669c:	078e                	sll	a5,a5,0x3
    8000669e:	97ba                	add	a5,a5,a4
    800066a0:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800066a2:	00278713          	add	a4,a5,2
    800066a6:	0712                	sll	a4,a4,0x4
    800066a8:	9726                	add	a4,a4,s1
    800066aa:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800066ae:	e721                	bnez	a4,800066f6 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800066b0:	0789                	add	a5,a5,2
    800066b2:	0792                	sll	a5,a5,0x4
    800066b4:	97a6                	add	a5,a5,s1
    800066b6:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800066b8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800066bc:	ffffc097          	auipc	ra,0xffffc
    800066c0:	c9e080e7          	jalr	-866(ra) # 8000235a <wakeup>

    disk.used_idx += 1;
    800066c4:	0204d783          	lhu	a5,32(s1)
    800066c8:	2785                	addw	a5,a5,1
    800066ca:	17c2                	sll	a5,a5,0x30
    800066cc:	93c1                	srl	a5,a5,0x30
    800066ce:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800066d2:	6898                	ld	a4,16(s1)
    800066d4:	00275703          	lhu	a4,2(a4)
    800066d8:	faf71ce3          	bne	a4,a5,80006690 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800066dc:	0023c517          	auipc	a0,0x23c
    800066e0:	e8c50513          	add	a0,a0,-372 # 80242568 <disk+0x128>
    800066e4:	ffffa097          	auipc	ra,0xffffa
    800066e8:	66c080e7          	jalr	1644(ra) # 80000d50 <release>
}
    800066ec:	60e2                	ld	ra,24(sp)
    800066ee:	6442                	ld	s0,16(sp)
    800066f0:	64a2                	ld	s1,8(sp)
    800066f2:	6105                	add	sp,sp,32
    800066f4:	8082                	ret
      panic("virtio_disk_intr status");
    800066f6:	00002517          	auipc	a0,0x2
    800066fa:	17250513          	add	a0,a0,370 # 80008868 <syscalls+0x3f0>
    800066fe:	ffffa097          	auipc	ra,0xffffa
    80006702:	e3e080e7          	jalr	-450(ra) # 8000053c <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	sll	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	sll	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
