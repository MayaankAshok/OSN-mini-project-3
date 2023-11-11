
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a4010113          	add	sp,sp,-1472 # 80008a40 <stack0>
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
    80000054:	8b070713          	add	a4,a4,-1872 # 80008900 <timer_scratch>
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
    80000066:	09e78793          	add	a5,a5,158 # 80006100 <timervec>
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
    8000009a:	7ff70713          	add	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc28f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	add	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dc678793          	add	a5,a5,-570 # 80000e72 <main>
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
    8000012e:	592080e7          	jalr	1426(ra) # 800026bc <either_copyin>
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
    80000188:	8bc50513          	add	a0,a0,-1860 # 80010a40 <cons>
    8000018c:	00001097          	auipc	ra,0x1
    80000190:	a46080e7          	jalr	-1466(ra) # 80000bd2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000194:	00011497          	auipc	s1,0x11
    80000198:	8ac48493          	add	s1,s1,-1876 # 80010a40 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    8000019c:	00011917          	auipc	s2,0x11
    800001a0:	93c90913          	add	s2,s2,-1732 # 80010ad8 <cons+0x98>
  while(n > 0){
    800001a4:	09305263          	blez	s3,80000228 <consoleread+0xc4>
    while(cons.r == cons.w){
    800001a8:	0984a783          	lw	a5,152(s1)
    800001ac:	09c4a703          	lw	a4,156(s1)
    800001b0:	02f71763          	bne	a4,a5,800001de <consoleread+0x7a>
      if(killed(myproc())){
    800001b4:	00002097          	auipc	ra,0x2
    800001b8:	81c080e7          	jalr	-2020(ra) # 800019d0 <myproc>
    800001bc:	00002097          	auipc	ra,0x2
    800001c0:	34a080e7          	jalr	842(ra) # 80002506 <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	088080e7          	jalr	136(ra) # 80002252 <sleep>
    while(cons.r == cons.w){
    800001d2:	0984a783          	lw	a5,152(s1)
    800001d6:	09c4a703          	lw	a4,156(s1)
    800001da:	fcf70de3          	beq	a4,a5,800001b4 <consoleread+0x50>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001de:	00011717          	auipc	a4,0x11
    800001e2:	86270713          	add	a4,a4,-1950 # 80010a40 <cons>
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
    80000214:	456080e7          	jalr	1110(ra) # 80002666 <either_copyout>
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
    8000022c:	81850513          	add	a0,a0,-2024 # 80010a40 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a56080e7          	jalr	-1450(ra) # 80000c86 <release>

  return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xec>
        release(&cons.lock);
    8000023e:	00011517          	auipc	a0,0x11
    80000242:	80250513          	add	a0,a0,-2046 # 80010a40 <cons>
    80000246:	00001097          	auipc	ra,0x1
    8000024a:	a40080e7          	jalr	-1472(ra) # 80000c86 <release>
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
    80000272:	86f72523          	sw	a5,-1942(a4) # 80010ad8 <cons+0x98>
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
    800002cc:	77850513          	add	a0,a0,1912 # 80010a40 <cons>
    800002d0:	00001097          	auipc	ra,0x1
    800002d4:	902080e7          	jalr	-1790(ra) # 80000bd2 <acquire>

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
    800002f2:	424080e7          	jalr	1060(ra) # 80002712 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f6:	00010517          	auipc	a0,0x10
    800002fa:	74a50513          	add	a0,a0,1866 # 80010a40 <cons>
    800002fe:	00001097          	auipc	ra,0x1
    80000302:	988080e7          	jalr	-1656(ra) # 80000c86 <release>
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
    8000031e:	72670713          	add	a4,a4,1830 # 80010a40 <cons>
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
    80000348:	6fc78793          	add	a5,a5,1788 # 80010a40 <cons>
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
    80000376:	7667a783          	lw	a5,1894(a5) # 80010ad8 <cons+0x98>
    8000037a:	9f1d                	subw	a4,a4,a5
    8000037c:	08000793          	li	a5,128
    80000380:	f6f71be3          	bne	a4,a5,800002f6 <consoleintr+0x3c>
    80000384:	a07d                	j	80000432 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000386:	00010717          	auipc	a4,0x10
    8000038a:	6ba70713          	add	a4,a4,1722 # 80010a40 <cons>
    8000038e:	0a072783          	lw	a5,160(a4)
    80000392:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000396:	00010497          	auipc	s1,0x10
    8000039a:	6aa48493          	add	s1,s1,1706 # 80010a40 <cons>
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
    800003d6:	66e70713          	add	a4,a4,1646 # 80010a40 <cons>
    800003da:	0a072783          	lw	a5,160(a4)
    800003de:	09c72703          	lw	a4,156(a4)
    800003e2:	f0f70ae3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
      cons.e--;
    800003e6:	37fd                	addw	a5,a5,-1
    800003e8:	00010717          	auipc	a4,0x10
    800003ec:	6ef72c23          	sw	a5,1784(a4) # 80010ae0 <cons+0xa0>
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
    80000412:	63278793          	add	a5,a5,1586 # 80010a40 <cons>
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
    80000436:	6ac7a523          	sw	a2,1706(a5) # 80010adc <cons+0x9c>
        wakeup(&cons.r);
    8000043a:	00010517          	auipc	a0,0x10
    8000043e:	69e50513          	add	a0,a0,1694 # 80010ad8 <cons+0x98>
    80000442:	00002097          	auipc	ra,0x2
    80000446:	e74080e7          	jalr	-396(ra) # 800022b6 <wakeup>
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
    80000460:	5e450513          	add	a0,a0,1508 # 80010a40 <cons>
    80000464:	00000097          	auipc	ra,0x0
    80000468:	6de080e7          	jalr	1758(ra) # 80000b42 <initlock>

  uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	32c080e7          	jalr	812(ra) # 80000798 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000474:	00021797          	auipc	a5,0x21
    80000478:	f6478793          	add	a5,a5,-156 # 800213d8 <devsw>
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
    8000054c:	5a07ac23          	sw	zero,1464(a5) # 80010b00 <pr+0x18>
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
    8000056e:	b5e50513          	add	a0,a0,-1186 # 800080c8 <digits+0x88>
    80000572:	00000097          	auipc	ra,0x0
    80000576:	014080e7          	jalr	20(ra) # 80000586 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057a:	4785                	li	a5,1
    8000057c:	00008717          	auipc	a4,0x8
    80000580:	34f72223          	sw	a5,836(a4) # 800088c0 <panicked>
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
    800005bc:	548dad83          	lw	s11,1352(s11) # 80010b00 <pr+0x18>
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
    800005fa:	4f250513          	add	a0,a0,1266 # 80010ae8 <pr>
    800005fe:	00000097          	auipc	ra,0x0
    80000602:	5d4080e7          	jalr	1492(ra) # 80000bd2 <acquire>
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
    80000758:	39450513          	add	a0,a0,916 # 80010ae8 <pr>
    8000075c:	00000097          	auipc	ra,0x0
    80000760:	52a080e7          	jalr	1322(ra) # 80000c86 <release>
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
    80000774:	37848493          	add	s1,s1,888 # 80010ae8 <pr>
    80000778:	00008597          	auipc	a1,0x8
    8000077c:	8c058593          	add	a1,a1,-1856 # 80008038 <etext+0x38>
    80000780:	8526                	mv	a0,s1
    80000782:	00000097          	auipc	ra,0x0
    80000786:	3c0080e7          	jalr	960(ra) # 80000b42 <initlock>
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
    800007d4:	33850513          	add	a0,a0,824 # 80010b08 <uart_tx_lock>
    800007d8:	00000097          	auipc	ra,0x0
    800007dc:	36a080e7          	jalr	874(ra) # 80000b42 <initlock>
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
    800007f8:	392080e7          	jalr	914(ra) # 80000b86 <push_off>

  if(panicked){
    800007fc:	00008797          	auipc	a5,0x8
    80000800:	0c47a783          	lw	a5,196(a5) # 800088c0 <panicked>
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
    80000826:	404080e7          	jalr	1028(ra) # 80000c26 <pop_off>
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
    80000838:	0947b783          	ld	a5,148(a5) # 800088c8 <uart_tx_r>
    8000083c:	00008717          	auipc	a4,0x8
    80000840:	09473703          	ld	a4,148(a4) # 800088d0 <uart_tx_w>
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
    80000862:	2aaa0a13          	add	s4,s4,682 # 80010b08 <uart_tx_lock>
    uart_tx_r += 1;
    80000866:	00008497          	auipc	s1,0x8
    8000086a:	06248493          	add	s1,s1,98 # 800088c8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086e:	00008997          	auipc	s3,0x8
    80000872:	06298993          	add	s3,s3,98 # 800088d0 <uart_tx_w>
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
    80000894:	a26080e7          	jalr	-1498(ra) # 800022b6 <wakeup>
    
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
    800008d0:	23c50513          	add	a0,a0,572 # 80010b08 <uart_tx_lock>
    800008d4:	00000097          	auipc	ra,0x0
    800008d8:	2fe080e7          	jalr	766(ra) # 80000bd2 <acquire>
  if(panicked){
    800008dc:	00008797          	auipc	a5,0x8
    800008e0:	fe47a783          	lw	a5,-28(a5) # 800088c0 <panicked>
    800008e4:	e7c9                	bnez	a5,8000096e <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	fea73703          	ld	a4,-22(a4) # 800088d0 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	fda7b783          	ld	a5,-38(a5) # 800088c8 <uart_tx_r>
    800008f6:	02078793          	add	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fa:	00010997          	auipc	s3,0x10
    800008fe:	20e98993          	add	s3,s3,526 # 80010b08 <uart_tx_lock>
    80000902:	00008497          	auipc	s1,0x8
    80000906:	fc648493          	add	s1,s1,-58 # 800088c8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090a:	00008917          	auipc	s2,0x8
    8000090e:	fc690913          	add	s2,s2,-58 # 800088d0 <uart_tx_w>
    80000912:	00e79f63          	bne	a5,a4,80000930 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00002097          	auipc	ra,0x2
    8000091e:	938080e7          	jalr	-1736(ra) # 80002252 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	add	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00010497          	auipc	s1,0x10
    80000934:	1d848493          	add	s1,s1,472 # 80010b08 <uart_tx_lock>
    80000938:	01f77793          	and	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000942:	0705                	add	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	f8e7b623          	sd	a4,-116(a5) # 800088d0 <uart_tx_w>
  uartstart();
    8000094c:	00000097          	auipc	ra,0x0
    80000950:	ee8080e7          	jalr	-280(ra) # 80000834 <uartstart>
  release(&uart_tx_lock);
    80000954:	8526                	mv	a0,s1
    80000956:	00000097          	auipc	ra,0x0
    8000095a:	330080e7          	jalr	816(ra) # 80000c86 <release>
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
    800009ba:	15248493          	add	s1,s1,338 # 80010b08 <uart_tx_lock>
    800009be:	8526                	mv	a0,s1
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	212080e7          	jalr	530(ra) # 80000bd2 <acquire>
  uartstart();
    800009c8:	00000097          	auipc	ra,0x0
    800009cc:	e6c080e7          	jalr	-404(ra) # 80000834 <uartstart>
  release(&uart_tx_lock);
    800009d0:	8526                	mv	a0,s1
    800009d2:	00000097          	auipc	ra,0x0
    800009d6:	2b4080e7          	jalr	692(ra) # 80000c86 <release>
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
    800009e4:	1101                	add	sp,sp,-32
    800009e6:	ec06                	sd	ra,24(sp)
    800009e8:	e822                	sd	s0,16(sp)
    800009ea:	e426                	sd	s1,8(sp)
    800009ec:	e04a                	sd	s2,0(sp)
    800009ee:	1000                	add	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f0:	03451793          	sll	a5,a0,0x34
    800009f4:	ebb9                	bnez	a5,80000a4a <kfree+0x66>
    800009f6:	84aa                	mv	s1,a0
    800009f8:	00022797          	auipc	a5,0x22
    800009fc:	b7878793          	add	a5,a5,-1160 # 80022570 <end>
    80000a00:	04f56563          	bltu	a0,a5,80000a4a <kfree+0x66>
    80000a04:	47c5                	li	a5,17
    80000a06:	07ee                	sll	a5,a5,0x1b
    80000a08:	04f57163          	bgeu	a0,a5,80000a4a <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a0c:	6605                	lui	a2,0x1
    80000a0e:	4585                	li	a1,1
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	2be080e7          	jalr	702(ra) # 80000cce <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a18:	00010917          	auipc	s2,0x10
    80000a1c:	12890913          	add	s2,s2,296 # 80010b40 <kmem>
    80000a20:	854a                	mv	a0,s2
    80000a22:	00000097          	auipc	ra,0x0
    80000a26:	1b0080e7          	jalr	432(ra) # 80000bd2 <acquire>
  r->next = kmem.freelist;
    80000a2a:	01893783          	ld	a5,24(s2)
    80000a2e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a30:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	250080e7          	jalr	592(ra) # 80000c86 <release>
}
    80000a3e:	60e2                	ld	ra,24(sp)
    80000a40:	6442                	ld	s0,16(sp)
    80000a42:	64a2                	ld	s1,8(sp)
    80000a44:	6902                	ld	s2,0(sp)
    80000a46:	6105                	add	sp,sp,32
    80000a48:	8082                	ret
    panic("kfree");
    80000a4a:	00007517          	auipc	a0,0x7
    80000a4e:	61650513          	add	a0,a0,1558 # 80008060 <digits+0x20>
    80000a52:	00000097          	auipc	ra,0x0
    80000a56:	aea080e7          	jalr	-1302(ra) # 8000053c <panic>

0000000080000a5a <freerange>:
{
    80000a5a:	7179                	add	sp,sp,-48
    80000a5c:	f406                	sd	ra,40(sp)
    80000a5e:	f022                	sd	s0,32(sp)
    80000a60:	ec26                	sd	s1,24(sp)
    80000a62:	e84a                	sd	s2,16(sp)
    80000a64:	e44e                	sd	s3,8(sp)
    80000a66:	e052                	sd	s4,0(sp)
    80000a68:	1800                	add	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6a:	6785                	lui	a5,0x1
    80000a6c:	fff78713          	add	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a70:	00e504b3          	add	s1,a0,a4
    80000a74:	777d                	lui	a4,0xfffff
    80000a76:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a78:	94be                	add	s1,s1,a5
    80000a7a:	0095ee63          	bltu	a1,s1,80000a96 <freerange+0x3c>
    80000a7e:	892e                	mv	s2,a1
    kfree(p);
    80000a80:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a82:	6985                	lui	s3,0x1
    kfree(p);
    80000a84:	01448533          	add	a0,s1,s4
    80000a88:	00000097          	auipc	ra,0x0
    80000a8c:	f5c080e7          	jalr	-164(ra) # 800009e4 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a90:	94ce                	add	s1,s1,s3
    80000a92:	fe9979e3          	bgeu	s2,s1,80000a84 <freerange+0x2a>
}
    80000a96:	70a2                	ld	ra,40(sp)
    80000a98:	7402                	ld	s0,32(sp)
    80000a9a:	64e2                	ld	s1,24(sp)
    80000a9c:	6942                	ld	s2,16(sp)
    80000a9e:	69a2                	ld	s3,8(sp)
    80000aa0:	6a02                	ld	s4,0(sp)
    80000aa2:	6145                	add	sp,sp,48
    80000aa4:	8082                	ret

0000000080000aa6 <kinit>:
{
    80000aa6:	1141                	add	sp,sp,-16
    80000aa8:	e406                	sd	ra,8(sp)
    80000aaa:	e022                	sd	s0,0(sp)
    80000aac:	0800                	add	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aae:	00007597          	auipc	a1,0x7
    80000ab2:	5ba58593          	add	a1,a1,1466 # 80008068 <digits+0x28>
    80000ab6:	00010517          	auipc	a0,0x10
    80000aba:	08a50513          	add	a0,a0,138 # 80010b40 <kmem>
    80000abe:	00000097          	auipc	ra,0x0
    80000ac2:	084080e7          	jalr	132(ra) # 80000b42 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac6:	45c5                	li	a1,17
    80000ac8:	05ee                	sll	a1,a1,0x1b
    80000aca:	00022517          	auipc	a0,0x22
    80000ace:	aa650513          	add	a0,a0,-1370 # 80022570 <end>
    80000ad2:	00000097          	auipc	ra,0x0
    80000ad6:	f88080e7          	jalr	-120(ra) # 80000a5a <freerange>
}
    80000ada:	60a2                	ld	ra,8(sp)
    80000adc:	6402                	ld	s0,0(sp)
    80000ade:	0141                	add	sp,sp,16
    80000ae0:	8082                	ret

0000000080000ae2 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae2:	1101                	add	sp,sp,-32
    80000ae4:	ec06                	sd	ra,24(sp)
    80000ae6:	e822                	sd	s0,16(sp)
    80000ae8:	e426                	sd	s1,8(sp)
    80000aea:	1000                	add	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000aec:	00010497          	auipc	s1,0x10
    80000af0:	05448493          	add	s1,s1,84 # 80010b40 <kmem>
    80000af4:	8526                	mv	a0,s1
    80000af6:	00000097          	auipc	ra,0x0
    80000afa:	0dc080e7          	jalr	220(ra) # 80000bd2 <acquire>
  r = kmem.freelist;
    80000afe:	6c84                	ld	s1,24(s1)
  if(r)
    80000b00:	c885                	beqz	s1,80000b30 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b02:	609c                	ld	a5,0(s1)
    80000b04:	00010517          	auipc	a0,0x10
    80000b08:	03c50513          	add	a0,a0,60 # 80010b40 <kmem>
    80000b0c:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b0e:	00000097          	auipc	ra,0x0
    80000b12:	178080e7          	jalr	376(ra) # 80000c86 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b16:	6605                	lui	a2,0x1
    80000b18:	4595                	li	a1,5
    80000b1a:	8526                	mv	a0,s1
    80000b1c:	00000097          	auipc	ra,0x0
    80000b20:	1b2080e7          	jalr	434(ra) # 80000cce <memset>
  return (void*)r;
}
    80000b24:	8526                	mv	a0,s1
    80000b26:	60e2                	ld	ra,24(sp)
    80000b28:	6442                	ld	s0,16(sp)
    80000b2a:	64a2                	ld	s1,8(sp)
    80000b2c:	6105                	add	sp,sp,32
    80000b2e:	8082                	ret
  release(&kmem.lock);
    80000b30:	00010517          	auipc	a0,0x10
    80000b34:	01050513          	add	a0,a0,16 # 80010b40 <kmem>
    80000b38:	00000097          	auipc	ra,0x0
    80000b3c:	14e080e7          	jalr	334(ra) # 80000c86 <release>
  if(r)
    80000b40:	b7d5                	j	80000b24 <kalloc+0x42>

0000000080000b42 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b42:	1141                	add	sp,sp,-16
    80000b44:	e422                	sd	s0,8(sp)
    80000b46:	0800                	add	s0,sp,16
  lk->name = name;
    80000b48:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4a:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b4e:	00053823          	sd	zero,16(a0)
}
    80000b52:	6422                	ld	s0,8(sp)
    80000b54:	0141                	add	sp,sp,16
    80000b56:	8082                	ret

0000000080000b58 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b58:	411c                	lw	a5,0(a0)
    80000b5a:	e399                	bnez	a5,80000b60 <holding+0x8>
    80000b5c:	4501                	li	a0,0
  return r;
}
    80000b5e:	8082                	ret
{
    80000b60:	1101                	add	sp,sp,-32
    80000b62:	ec06                	sd	ra,24(sp)
    80000b64:	e822                	sd	s0,16(sp)
    80000b66:	e426                	sd	s1,8(sp)
    80000b68:	1000                	add	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	6904                	ld	s1,16(a0)
    80000b6c:	00001097          	auipc	ra,0x1
    80000b70:	e48080e7          	jalr	-440(ra) # 800019b4 <mycpu>
    80000b74:	40a48533          	sub	a0,s1,a0
    80000b78:	00153513          	seqz	a0,a0
}
    80000b7c:	60e2                	ld	ra,24(sp)
    80000b7e:	6442                	ld	s0,16(sp)
    80000b80:	64a2                	ld	s1,8(sp)
    80000b82:	6105                	add	sp,sp,32
    80000b84:	8082                	ret

0000000080000b86 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b86:	1101                	add	sp,sp,-32
    80000b88:	ec06                	sd	ra,24(sp)
    80000b8a:	e822                	sd	s0,16(sp)
    80000b8c:	e426                	sd	s1,8(sp)
    80000b8e:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b90:	100024f3          	csrr	s1,sstatus
    80000b94:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b98:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9a:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b9e:	00001097          	auipc	ra,0x1
    80000ba2:	e16080e7          	jalr	-490(ra) # 800019b4 <mycpu>
    80000ba6:	5d3c                	lw	a5,120(a0)
    80000ba8:	cf89                	beqz	a5,80000bc2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000baa:	00001097          	auipc	ra,0x1
    80000bae:	e0a080e7          	jalr	-502(ra) # 800019b4 <mycpu>
    80000bb2:	5d3c                	lw	a5,120(a0)
    80000bb4:	2785                	addw	a5,a5,1
    80000bb6:	dd3c                	sw	a5,120(a0)
}
    80000bb8:	60e2                	ld	ra,24(sp)
    80000bba:	6442                	ld	s0,16(sp)
    80000bbc:	64a2                	ld	s1,8(sp)
    80000bbe:	6105                	add	sp,sp,32
    80000bc0:	8082                	ret
    mycpu()->intena = old;
    80000bc2:	00001097          	auipc	ra,0x1
    80000bc6:	df2080e7          	jalr	-526(ra) # 800019b4 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bca:	8085                	srl	s1,s1,0x1
    80000bcc:	8885                	and	s1,s1,1
    80000bce:	dd64                	sw	s1,124(a0)
    80000bd0:	bfe9                	j	80000baa <push_off+0x24>

0000000080000bd2 <acquire>:
{
    80000bd2:	1101                	add	sp,sp,-32
    80000bd4:	ec06                	sd	ra,24(sp)
    80000bd6:	e822                	sd	s0,16(sp)
    80000bd8:	e426                	sd	s1,8(sp)
    80000bda:	1000                	add	s0,sp,32
    80000bdc:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bde:	00000097          	auipc	ra,0x0
    80000be2:	fa8080e7          	jalr	-88(ra) # 80000b86 <push_off>
  if(holding(lk))
    80000be6:	8526                	mv	a0,s1
    80000be8:	00000097          	auipc	ra,0x0
    80000bec:	f70080e7          	jalr	-144(ra) # 80000b58 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf0:	4705                	li	a4,1
  if(holding(lk))
    80000bf2:	e115                	bnez	a0,80000c16 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	87ba                	mv	a5,a4
    80000bf6:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfa:	2781                	sext.w	a5,a5
    80000bfc:	ffe5                	bnez	a5,80000bf4 <acquire+0x22>
  __sync_synchronize();
    80000bfe:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c02:	00001097          	auipc	ra,0x1
    80000c06:	db2080e7          	jalr	-590(ra) # 800019b4 <mycpu>
    80000c0a:	e888                	sd	a0,16(s1)
}
    80000c0c:	60e2                	ld	ra,24(sp)
    80000c0e:	6442                	ld	s0,16(sp)
    80000c10:	64a2                	ld	s1,8(sp)
    80000c12:	6105                	add	sp,sp,32
    80000c14:	8082                	ret
    panic("acquire");
    80000c16:	00007517          	auipc	a0,0x7
    80000c1a:	45a50513          	add	a0,a0,1114 # 80008070 <digits+0x30>
    80000c1e:	00000097          	auipc	ra,0x0
    80000c22:	91e080e7          	jalr	-1762(ra) # 8000053c <panic>

0000000080000c26 <pop_off>:

void
pop_off(void)
{
    80000c26:	1141                	add	sp,sp,-16
    80000c28:	e406                	sd	ra,8(sp)
    80000c2a:	e022                	sd	s0,0(sp)
    80000c2c:	0800                	add	s0,sp,16
  struct cpu *c = mycpu();
    80000c2e:	00001097          	auipc	ra,0x1
    80000c32:	d86080e7          	jalr	-634(ra) # 800019b4 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c36:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3a:	8b89                	and	a5,a5,2
  if(intr_get())
    80000c3c:	e78d                	bnez	a5,80000c66 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c3e:	5d3c                	lw	a5,120(a0)
    80000c40:	02f05b63          	blez	a5,80000c76 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c44:	37fd                	addw	a5,a5,-1
    80000c46:	0007871b          	sext.w	a4,a5
    80000c4a:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c4c:	eb09                	bnez	a4,80000c5e <pop_off+0x38>
    80000c4e:	5d7c                	lw	a5,124(a0)
    80000c50:	c799                	beqz	a5,80000c5e <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c52:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c56:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5a:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c5e:	60a2                	ld	ra,8(sp)
    80000c60:	6402                	ld	s0,0(sp)
    80000c62:	0141                	add	sp,sp,16
    80000c64:	8082                	ret
    panic("pop_off - interruptible");
    80000c66:	00007517          	auipc	a0,0x7
    80000c6a:	41250513          	add	a0,a0,1042 # 80008078 <digits+0x38>
    80000c6e:	00000097          	auipc	ra,0x0
    80000c72:	8ce080e7          	jalr	-1842(ra) # 8000053c <panic>
    panic("pop_off");
    80000c76:	00007517          	auipc	a0,0x7
    80000c7a:	41a50513          	add	a0,a0,1050 # 80008090 <digits+0x50>
    80000c7e:	00000097          	auipc	ra,0x0
    80000c82:	8be080e7          	jalr	-1858(ra) # 8000053c <panic>

0000000080000c86 <release>:
{
    80000c86:	1101                	add	sp,sp,-32
    80000c88:	ec06                	sd	ra,24(sp)
    80000c8a:	e822                	sd	s0,16(sp)
    80000c8c:	e426                	sd	s1,8(sp)
    80000c8e:	1000                	add	s0,sp,32
    80000c90:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c92:	00000097          	auipc	ra,0x0
    80000c96:	ec6080e7          	jalr	-314(ra) # 80000b58 <holding>
    80000c9a:	c115                	beqz	a0,80000cbe <release+0x38>
  lk->cpu = 0;
    80000c9c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca0:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca4:	0f50000f          	fence	iorw,ow
    80000ca8:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	f7a080e7          	jalr	-134(ra) # 80000c26 <pop_off>
}
    80000cb4:	60e2                	ld	ra,24(sp)
    80000cb6:	6442                	ld	s0,16(sp)
    80000cb8:	64a2                	ld	s1,8(sp)
    80000cba:	6105                	add	sp,sp,32
    80000cbc:	8082                	ret
    panic("release");
    80000cbe:	00007517          	auipc	a0,0x7
    80000cc2:	3da50513          	add	a0,a0,986 # 80008098 <digits+0x58>
    80000cc6:	00000097          	auipc	ra,0x0
    80000cca:	876080e7          	jalr	-1930(ra) # 8000053c <panic>

0000000080000cce <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cce:	1141                	add	sp,sp,-16
    80000cd0:	e422                	sd	s0,8(sp)
    80000cd2:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd4:	ca19                	beqz	a2,80000cea <memset+0x1c>
    80000cd6:	87aa                	mv	a5,a0
    80000cd8:	1602                	sll	a2,a2,0x20
    80000cda:	9201                	srl	a2,a2,0x20
    80000cdc:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce4:	0785                	add	a5,a5,1
    80000ce6:	fee79de3          	bne	a5,a4,80000ce0 <memset+0x12>
  }
  return dst;
}
    80000cea:	6422                	ld	s0,8(sp)
    80000cec:	0141                	add	sp,sp,16
    80000cee:	8082                	ret

0000000080000cf0 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf0:	1141                	add	sp,sp,-16
    80000cf2:	e422                	sd	s0,8(sp)
    80000cf4:	0800                	add	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cf6:	ca05                	beqz	a2,80000d26 <memcmp+0x36>
    80000cf8:	fff6069b          	addw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000cfc:	1682                	sll	a3,a3,0x20
    80000cfe:	9281                	srl	a3,a3,0x20
    80000d00:	0685                	add	a3,a3,1
    80000d02:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d04:	00054783          	lbu	a5,0(a0)
    80000d08:	0005c703          	lbu	a4,0(a1)
    80000d0c:	00e79863          	bne	a5,a4,80000d1c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d10:	0505                	add	a0,a0,1
    80000d12:	0585                	add	a1,a1,1
  while(n-- > 0){
    80000d14:	fed518e3          	bne	a0,a3,80000d04 <memcmp+0x14>
  }

  return 0;
    80000d18:	4501                	li	a0,0
    80000d1a:	a019                	j	80000d20 <memcmp+0x30>
      return *s1 - *s2;
    80000d1c:	40e7853b          	subw	a0,a5,a4
}
    80000d20:	6422                	ld	s0,8(sp)
    80000d22:	0141                	add	sp,sp,16
    80000d24:	8082                	ret
  return 0;
    80000d26:	4501                	li	a0,0
    80000d28:	bfe5                	j	80000d20 <memcmp+0x30>

0000000080000d2a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2a:	1141                	add	sp,sp,-16
    80000d2c:	e422                	sd	s0,8(sp)
    80000d2e:	0800                	add	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d30:	c205                	beqz	a2,80000d50 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d32:	02a5e263          	bltu	a1,a0,80000d56 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d36:	1602                	sll	a2,a2,0x20
    80000d38:	9201                	srl	a2,a2,0x20
    80000d3a:	00c587b3          	add	a5,a1,a2
{
    80000d3e:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d40:	0585                	add	a1,a1,1
    80000d42:	0705                	add	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdca91>
    80000d44:	fff5c683          	lbu	a3,-1(a1)
    80000d48:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d4c:	fef59ae3          	bne	a1,a5,80000d40 <memmove+0x16>

  return dst;
}
    80000d50:	6422                	ld	s0,8(sp)
    80000d52:	0141                	add	sp,sp,16
    80000d54:	8082                	ret
  if(s < d && s + n > d){
    80000d56:	02061693          	sll	a3,a2,0x20
    80000d5a:	9281                	srl	a3,a3,0x20
    80000d5c:	00d58733          	add	a4,a1,a3
    80000d60:	fce57be3          	bgeu	a0,a4,80000d36 <memmove+0xc>
    d += n;
    80000d64:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d66:	fff6079b          	addw	a5,a2,-1
    80000d6a:	1782                	sll	a5,a5,0x20
    80000d6c:	9381                	srl	a5,a5,0x20
    80000d6e:	fff7c793          	not	a5,a5
    80000d72:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d74:	177d                	add	a4,a4,-1
    80000d76:	16fd                	add	a3,a3,-1
    80000d78:	00074603          	lbu	a2,0(a4)
    80000d7c:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d80:	fee79ae3          	bne	a5,a4,80000d74 <memmove+0x4a>
    80000d84:	b7f1                	j	80000d50 <memmove+0x26>

0000000080000d86 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d86:	1141                	add	sp,sp,-16
    80000d88:	e406                	sd	ra,8(sp)
    80000d8a:	e022                	sd	s0,0(sp)
    80000d8c:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
    80000d8e:	00000097          	auipc	ra,0x0
    80000d92:	f9c080e7          	jalr	-100(ra) # 80000d2a <memmove>
}
    80000d96:	60a2                	ld	ra,8(sp)
    80000d98:	6402                	ld	s0,0(sp)
    80000d9a:	0141                	add	sp,sp,16
    80000d9c:	8082                	ret

0000000080000d9e <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d9e:	1141                	add	sp,sp,-16
    80000da0:	e422                	sd	s0,8(sp)
    80000da2:	0800                	add	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da4:	ce11                	beqz	a2,80000dc0 <strncmp+0x22>
    80000da6:	00054783          	lbu	a5,0(a0)
    80000daa:	cf89                	beqz	a5,80000dc4 <strncmp+0x26>
    80000dac:	0005c703          	lbu	a4,0(a1)
    80000db0:	00f71a63          	bne	a4,a5,80000dc4 <strncmp+0x26>
    n--, p++, q++;
    80000db4:	367d                	addw	a2,a2,-1
    80000db6:	0505                	add	a0,a0,1
    80000db8:	0585                	add	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dba:	f675                	bnez	a2,80000da6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dbc:	4501                	li	a0,0
    80000dbe:	a809                	j	80000dd0 <strncmp+0x32>
    80000dc0:	4501                	li	a0,0
    80000dc2:	a039                	j	80000dd0 <strncmp+0x32>
  if(n == 0)
    80000dc4:	ca09                	beqz	a2,80000dd6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dc6:	00054503          	lbu	a0,0(a0)
    80000dca:	0005c783          	lbu	a5,0(a1)
    80000dce:	9d1d                	subw	a0,a0,a5
}
    80000dd0:	6422                	ld	s0,8(sp)
    80000dd2:	0141                	add	sp,sp,16
    80000dd4:	8082                	ret
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	bfe5                	j	80000dd0 <strncmp+0x32>

0000000080000dda <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dda:	1141                	add	sp,sp,-16
    80000ddc:	e422                	sd	s0,8(sp)
    80000dde:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de0:	87aa                	mv	a5,a0
    80000de2:	86b2                	mv	a3,a2
    80000de4:	367d                	addw	a2,a2,-1
    80000de6:	00d05963          	blez	a3,80000df8 <strncpy+0x1e>
    80000dea:	0785                	add	a5,a5,1
    80000dec:	0005c703          	lbu	a4,0(a1)
    80000df0:	fee78fa3          	sb	a4,-1(a5)
    80000df4:	0585                	add	a1,a1,1
    80000df6:	f775                	bnez	a4,80000de2 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df8:	873e                	mv	a4,a5
    80000dfa:	9fb5                	addw	a5,a5,a3
    80000dfc:	37fd                	addw	a5,a5,-1
    80000dfe:	00c05963          	blez	a2,80000e10 <strncpy+0x36>
    *s++ = 0;
    80000e02:	0705                	add	a4,a4,1
    80000e04:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000e08:	40e786bb          	subw	a3,a5,a4
    80000e0c:	fed04be3          	bgtz	a3,80000e02 <strncpy+0x28>
  return os;
}
    80000e10:	6422                	ld	s0,8(sp)
    80000e12:	0141                	add	sp,sp,16
    80000e14:	8082                	ret

0000000080000e16 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e16:	1141                	add	sp,sp,-16
    80000e18:	e422                	sd	s0,8(sp)
    80000e1a:	0800                	add	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e1c:	02c05363          	blez	a2,80000e42 <safestrcpy+0x2c>
    80000e20:	fff6069b          	addw	a3,a2,-1
    80000e24:	1682                	sll	a3,a3,0x20
    80000e26:	9281                	srl	a3,a3,0x20
    80000e28:	96ae                	add	a3,a3,a1
    80000e2a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e2c:	00d58963          	beq	a1,a3,80000e3e <safestrcpy+0x28>
    80000e30:	0585                	add	a1,a1,1
    80000e32:	0785                	add	a5,a5,1
    80000e34:	fff5c703          	lbu	a4,-1(a1)
    80000e38:	fee78fa3          	sb	a4,-1(a5)
    80000e3c:	fb65                	bnez	a4,80000e2c <safestrcpy+0x16>
    ;
  *s = 0;
    80000e3e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e42:	6422                	ld	s0,8(sp)
    80000e44:	0141                	add	sp,sp,16
    80000e46:	8082                	ret

0000000080000e48 <strlen>:

int
strlen(const char *s)
{
    80000e48:	1141                	add	sp,sp,-16
    80000e4a:	e422                	sd	s0,8(sp)
    80000e4c:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e4e:	00054783          	lbu	a5,0(a0)
    80000e52:	cf91                	beqz	a5,80000e6e <strlen+0x26>
    80000e54:	0505                	add	a0,a0,1
    80000e56:	87aa                	mv	a5,a0
    80000e58:	86be                	mv	a3,a5
    80000e5a:	0785                	add	a5,a5,1
    80000e5c:	fff7c703          	lbu	a4,-1(a5)
    80000e60:	ff65                	bnez	a4,80000e58 <strlen+0x10>
    80000e62:	40a6853b          	subw	a0,a3,a0
    80000e66:	2505                	addw	a0,a0,1
    ;
  return n;
}
    80000e68:	6422                	ld	s0,8(sp)
    80000e6a:	0141                	add	sp,sp,16
    80000e6c:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e6e:	4501                	li	a0,0
    80000e70:	bfe5                	j	80000e68 <strlen+0x20>

0000000080000e72 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e72:	1141                	add	sp,sp,-16
    80000e74:	e406                	sd	ra,8(sp)
    80000e76:	e022                	sd	s0,0(sp)
    80000e78:	0800                	add	s0,sp,16
  if(cpuid() == 0){
    80000e7a:	00001097          	auipc	ra,0x1
    80000e7e:	b2a080e7          	jalr	-1238(ra) # 800019a4 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e82:	00008717          	auipc	a4,0x8
    80000e86:	a5670713          	add	a4,a4,-1450 # 800088d8 <started>
  if(cpuid() == 0){
    80000e8a:	c139                	beqz	a0,80000ed0 <main+0x5e>
    while(started == 0)
    80000e8c:	431c                	lw	a5,0(a4)
    80000e8e:	2781                	sext.w	a5,a5
    80000e90:	dff5                	beqz	a5,80000e8c <main+0x1a>
      ;
    __sync_synchronize();
    80000e92:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	b0e080e7          	jalr	-1266(ra) # 800019a4 <cpuid>
    80000e9e:	85aa                	mv	a1,a0
    80000ea0:	00007517          	auipc	a0,0x7
    80000ea4:	21850513          	add	a0,a0,536 # 800080b8 <digits+0x78>
    80000ea8:	fffff097          	auipc	ra,0xfffff
    80000eac:	6de080e7          	jalr	1758(ra) # 80000586 <printf>
    kvminithart();    // turn on paging
    80000eb0:	00000097          	auipc	ra,0x0
    80000eb4:	0d8080e7          	jalr	216(ra) # 80000f88 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb8:	00002097          	auipc	ra,0x2
    80000ebc:	b46080e7          	jalr	-1210(ra) # 800029fe <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	280080e7          	jalr	640(ra) # 80006140 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	0f8080e7          	jalr	248(ra) # 80001fc0 <scheduler>
    consoleinit();
    80000ed0:	fffff097          	auipc	ra,0xfffff
    80000ed4:	57c080e7          	jalr	1404(ra) # 8000044c <consoleinit>
    printfinit();
    80000ed8:	00000097          	auipc	ra,0x0
    80000edc:	88e080e7          	jalr	-1906(ra) # 80000766 <printfinit>
    printf("\n");
    80000ee0:	00007517          	auipc	a0,0x7
    80000ee4:	1e850513          	add	a0,a0,488 # 800080c8 <digits+0x88>
    80000ee8:	fffff097          	auipc	ra,0xfffff
    80000eec:	69e080e7          	jalr	1694(ra) # 80000586 <printf>
    printf("xv6 kernel is booting\n");
    80000ef0:	00007517          	auipc	a0,0x7
    80000ef4:	1b050513          	add	a0,a0,432 # 800080a0 <digits+0x60>
    80000ef8:	fffff097          	auipc	ra,0xfffff
    80000efc:	68e080e7          	jalr	1678(ra) # 80000586 <printf>
    printf("\n");
    80000f00:	00007517          	auipc	a0,0x7
    80000f04:	1c850513          	add	a0,a0,456 # 800080c8 <digits+0x88>
    80000f08:	fffff097          	auipc	ra,0xfffff
    80000f0c:	67e080e7          	jalr	1662(ra) # 80000586 <printf>
    kinit();         // physical page allocator
    80000f10:	00000097          	auipc	ra,0x0
    80000f14:	b96080e7          	jalr	-1130(ra) # 80000aa6 <kinit>
    kvminit();       // create kernel page table
    80000f18:	00000097          	auipc	ra,0x0
    80000f1c:	310080e7          	jalr	784(ra) # 80001228 <kvminit>
    kvminithart();   // turn on paging
    80000f20:	00000097          	auipc	ra,0x0
    80000f24:	068080e7          	jalr	104(ra) # 80000f88 <kvminithart>
    procinit();      // process table
    80000f28:	00001097          	auipc	ra,0x1
    80000f2c:	9c8080e7          	jalr	-1592(ra) # 800018f0 <procinit>
    trapinit();      // trap vectors
    80000f30:	00002097          	auipc	ra,0x2
    80000f34:	aa6080e7          	jalr	-1370(ra) # 800029d6 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00002097          	auipc	ra,0x2
    80000f3c:	ac6080e7          	jalr	-1338(ra) # 800029fe <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	1ea080e7          	jalr	490(ra) # 8000612a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	1f8080e7          	jalr	504(ra) # 80006140 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	3ca080e7          	jalr	970(ra) # 8000331a <binit>
    iinit();         // inode table
    80000f58:	00003097          	auipc	ra,0x3
    80000f5c:	a68080e7          	jalr	-1432(ra) # 800039c0 <iinit>
    fileinit();      // file table
    80000f60:	00004097          	auipc	ra,0x4
    80000f64:	9de080e7          	jalr	-1570(ra) # 8000493e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	2e0080e7          	jalr	736(ra) # 80006248 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	d60080e7          	jalr	-672(ra) # 80001cd0 <userinit>
    __sync_synchronize();
    80000f78:	0ff0000f          	fence
    started = 1;
    80000f7c:	4785                	li	a5,1
    80000f7e:	00008717          	auipc	a4,0x8
    80000f82:	94f72d23          	sw	a5,-1702(a4) # 800088d8 <started>
    80000f86:	b789                	j	80000ec8 <main+0x56>

0000000080000f88 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f88:	1141                	add	sp,sp,-16
    80000f8a:	e422                	sd	s0,8(sp)
    80000f8c:	0800                	add	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f8e:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f92:	00008797          	auipc	a5,0x8
    80000f96:	94e7b783          	ld	a5,-1714(a5) # 800088e0 <kernel_pagetable>
    80000f9a:	83b1                	srl	a5,a5,0xc
    80000f9c:	577d                	li	a4,-1
    80000f9e:	177e                	sll	a4,a4,0x3f
    80000fa0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa2:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fa6:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000faa:	6422                	ld	s0,8(sp)
    80000fac:	0141                	add	sp,sp,16
    80000fae:	8082                	ret

0000000080000fb0 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb0:	7139                	add	sp,sp,-64
    80000fb2:	fc06                	sd	ra,56(sp)
    80000fb4:	f822                	sd	s0,48(sp)
    80000fb6:	f426                	sd	s1,40(sp)
    80000fb8:	f04a                	sd	s2,32(sp)
    80000fba:	ec4e                	sd	s3,24(sp)
    80000fbc:	e852                	sd	s4,16(sp)
    80000fbe:	e456                	sd	s5,8(sp)
    80000fc0:	e05a                	sd	s6,0(sp)
    80000fc2:	0080                	add	s0,sp,64
    80000fc4:	84aa                	mv	s1,a0
    80000fc6:	89ae                	mv	s3,a1
    80000fc8:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fca:	57fd                	li	a5,-1
    80000fcc:	83e9                	srl	a5,a5,0x1a
    80000fce:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd0:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd2:	04b7f263          	bgeu	a5,a1,80001016 <walk+0x66>
    panic("walk");
    80000fd6:	00007517          	auipc	a0,0x7
    80000fda:	0fa50513          	add	a0,a0,250 # 800080d0 <digits+0x90>
    80000fde:	fffff097          	auipc	ra,0xfffff
    80000fe2:	55e080e7          	jalr	1374(ra) # 8000053c <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fe6:	060a8663          	beqz	s5,80001052 <walk+0xa2>
    80000fea:	00000097          	auipc	ra,0x0
    80000fee:	af8080e7          	jalr	-1288(ra) # 80000ae2 <kalloc>
    80000ff2:	84aa                	mv	s1,a0
    80000ff4:	c529                	beqz	a0,8000103e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ff6:	6605                	lui	a2,0x1
    80000ff8:	4581                	li	a1,0
    80000ffa:	00000097          	auipc	ra,0x0
    80000ffe:	cd4080e7          	jalr	-812(ra) # 80000cce <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001002:	00c4d793          	srl	a5,s1,0xc
    80001006:	07aa                	sll	a5,a5,0xa
    80001008:	0017e793          	or	a5,a5,1
    8000100c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001010:	3a5d                	addw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdca87>
    80001012:	036a0063          	beq	s4,s6,80001032 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001016:	0149d933          	srl	s2,s3,s4
    8000101a:	1ff97913          	and	s2,s2,511
    8000101e:	090e                	sll	s2,s2,0x3
    80001020:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001022:	00093483          	ld	s1,0(s2)
    80001026:	0014f793          	and	a5,s1,1
    8000102a:	dfd5                	beqz	a5,80000fe6 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000102c:	80a9                	srl	s1,s1,0xa
    8000102e:	04b2                	sll	s1,s1,0xc
    80001030:	b7c5                	j	80001010 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001032:	00c9d513          	srl	a0,s3,0xc
    80001036:	1ff57513          	and	a0,a0,511
    8000103a:	050e                	sll	a0,a0,0x3
    8000103c:	9526                	add	a0,a0,s1
}
    8000103e:	70e2                	ld	ra,56(sp)
    80001040:	7442                	ld	s0,48(sp)
    80001042:	74a2                	ld	s1,40(sp)
    80001044:	7902                	ld	s2,32(sp)
    80001046:	69e2                	ld	s3,24(sp)
    80001048:	6a42                	ld	s4,16(sp)
    8000104a:	6aa2                	ld	s5,8(sp)
    8000104c:	6b02                	ld	s6,0(sp)
    8000104e:	6121                	add	sp,sp,64
    80001050:	8082                	ret
        return 0;
    80001052:	4501                	li	a0,0
    80001054:	b7ed                	j	8000103e <walk+0x8e>

0000000080001056 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001056:	57fd                	li	a5,-1
    80001058:	83e9                	srl	a5,a5,0x1a
    8000105a:	00b7f463          	bgeu	a5,a1,80001062 <walkaddr+0xc>
    return 0;
    8000105e:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001060:	8082                	ret
{
    80001062:	1141                	add	sp,sp,-16
    80001064:	e406                	sd	ra,8(sp)
    80001066:	e022                	sd	s0,0(sp)
    80001068:	0800                	add	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000106a:	4601                	li	a2,0
    8000106c:	00000097          	auipc	ra,0x0
    80001070:	f44080e7          	jalr	-188(ra) # 80000fb0 <walk>
  if(pte == 0)
    80001074:	c105                	beqz	a0,80001094 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001076:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001078:	0117f693          	and	a3,a5,17
    8000107c:	4745                	li	a4,17
    return 0;
    8000107e:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001080:	00e68663          	beq	a3,a4,8000108c <walkaddr+0x36>
}
    80001084:	60a2                	ld	ra,8(sp)
    80001086:	6402                	ld	s0,0(sp)
    80001088:	0141                	add	sp,sp,16
    8000108a:	8082                	ret
  pa = PTE2PA(*pte);
    8000108c:	83a9                	srl	a5,a5,0xa
    8000108e:	00c79513          	sll	a0,a5,0xc
  return pa;
    80001092:	bfcd                	j	80001084 <walkaddr+0x2e>
    return 0;
    80001094:	4501                	li	a0,0
    80001096:	b7fd                	j	80001084 <walkaddr+0x2e>

0000000080001098 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001098:	715d                	add	sp,sp,-80
    8000109a:	e486                	sd	ra,72(sp)
    8000109c:	e0a2                	sd	s0,64(sp)
    8000109e:	fc26                	sd	s1,56(sp)
    800010a0:	f84a                	sd	s2,48(sp)
    800010a2:	f44e                	sd	s3,40(sp)
    800010a4:	f052                	sd	s4,32(sp)
    800010a6:	ec56                	sd	s5,24(sp)
    800010a8:	e85a                	sd	s6,16(sp)
    800010aa:	e45e                	sd	s7,8(sp)
    800010ac:	0880                	add	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010ae:	c621                	beqz	a2,800010f6 <mappages+0x5e>
    800010b0:	8aaa                	mv	s5,a0
    800010b2:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010b4:	777d                	lui	a4,0xfffff
    800010b6:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010ba:	fff58993          	add	s3,a1,-1
    800010be:	99b2                	add	s3,s3,a2
    800010c0:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010c4:	893e                	mv	s2,a5
    800010c6:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V & PTE_W)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010ca:	6b85                	lui	s7,0x1
    800010cc:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d0:	4605                	li	a2,1
    800010d2:	85ca                	mv	a1,s2
    800010d4:	8556                	mv	a0,s5
    800010d6:	00000097          	auipc	ra,0x0
    800010da:	eda080e7          	jalr	-294(ra) # 80000fb0 <walk>
    800010de:	c505                	beqz	a0,80001106 <mappages+0x6e>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010e0:	80b1                	srl	s1,s1,0xc
    800010e2:	04aa                	sll	s1,s1,0xa
    800010e4:	0164e4b3          	or	s1,s1,s6
    800010e8:	0014e493          	or	s1,s1,1
    800010ec:	e104                	sd	s1,0(a0)
    if(a == last)
    800010ee:	03390863          	beq	s2,s3,8000111e <mappages+0x86>
    a += PGSIZE;
    800010f2:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010f4:	bfe1                	j	800010cc <mappages+0x34>
    panic("mappages: size");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	fe250513          	add	a0,a0,-30 # 800080d8 <digits+0x98>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	43e080e7          	jalr	1086(ra) # 8000053c <panic>
      return -1;
    80001106:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001108:	60a6                	ld	ra,72(sp)
    8000110a:	6406                	ld	s0,64(sp)
    8000110c:	74e2                	ld	s1,56(sp)
    8000110e:	7942                	ld	s2,48(sp)
    80001110:	79a2                	ld	s3,40(sp)
    80001112:	7a02                	ld	s4,32(sp)
    80001114:	6ae2                	ld	s5,24(sp)
    80001116:	6b42                	ld	s6,16(sp)
    80001118:	6ba2                	ld	s7,8(sp)
    8000111a:	6161                	add	sp,sp,80
    8000111c:	8082                	ret
  return 0;
    8000111e:	4501                	li	a0,0
    80001120:	b7e5                	j	80001108 <mappages+0x70>

0000000080001122 <kvmmap>:
{
    80001122:	1141                	add	sp,sp,-16
    80001124:	e406                	sd	ra,8(sp)
    80001126:	e022                	sd	s0,0(sp)
    80001128:	0800                	add	s0,sp,16
    8000112a:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000112c:	86b2                	mv	a3,a2
    8000112e:	863e                	mv	a2,a5
    80001130:	00000097          	auipc	ra,0x0
    80001134:	f68080e7          	jalr	-152(ra) # 80001098 <mappages>
    80001138:	e509                	bnez	a0,80001142 <kvmmap+0x20>
}
    8000113a:	60a2                	ld	ra,8(sp)
    8000113c:	6402                	ld	s0,0(sp)
    8000113e:	0141                	add	sp,sp,16
    80001140:	8082                	ret
    panic("kvmmap");
    80001142:	00007517          	auipc	a0,0x7
    80001146:	fa650513          	add	a0,a0,-90 # 800080e8 <digits+0xa8>
    8000114a:	fffff097          	auipc	ra,0xfffff
    8000114e:	3f2080e7          	jalr	1010(ra) # 8000053c <panic>

0000000080001152 <kvmmake>:
{
    80001152:	1101                	add	sp,sp,-32
    80001154:	ec06                	sd	ra,24(sp)
    80001156:	e822                	sd	s0,16(sp)
    80001158:	e426                	sd	s1,8(sp)
    8000115a:	e04a                	sd	s2,0(sp)
    8000115c:	1000                	add	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	984080e7          	jalr	-1660(ra) # 80000ae2 <kalloc>
    80001166:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001168:	6605                	lui	a2,0x1
    8000116a:	4581                	li	a1,0
    8000116c:	00000097          	auipc	ra,0x0
    80001170:	b62080e7          	jalr	-1182(ra) # 80000cce <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001174:	4719                	li	a4,6
    80001176:	6685                	lui	a3,0x1
    80001178:	10000637          	lui	a2,0x10000
    8000117c:	100005b7          	lui	a1,0x10000
    80001180:	8526                	mv	a0,s1
    80001182:	00000097          	auipc	ra,0x0
    80001186:	fa0080e7          	jalr	-96(ra) # 80001122 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000118a:	4719                	li	a4,6
    8000118c:	6685                	lui	a3,0x1
    8000118e:	10001637          	lui	a2,0x10001
    80001192:	100015b7          	lui	a1,0x10001
    80001196:	8526                	mv	a0,s1
    80001198:	00000097          	auipc	ra,0x0
    8000119c:	f8a080e7          	jalr	-118(ra) # 80001122 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011a0:	4719                	li	a4,6
    800011a2:	004006b7          	lui	a3,0x400
    800011a6:	0c000637          	lui	a2,0xc000
    800011aa:	0c0005b7          	lui	a1,0xc000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	f72080e7          	jalr	-142(ra) # 80001122 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011b8:	00007917          	auipc	s2,0x7
    800011bc:	e4890913          	add	s2,s2,-440 # 80008000 <etext>
    800011c0:	4729                	li	a4,10
    800011c2:	80007697          	auipc	a3,0x80007
    800011c6:	e3e68693          	add	a3,a3,-450 # 8000 <_entry-0x7fff8000>
    800011ca:	4605                	li	a2,1
    800011cc:	067e                	sll	a2,a2,0x1f
    800011ce:	85b2                	mv	a1,a2
    800011d0:	8526                	mv	a0,s1
    800011d2:	00000097          	auipc	ra,0x0
    800011d6:	f50080e7          	jalr	-176(ra) # 80001122 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011da:	4719                	li	a4,6
    800011dc:	46c5                	li	a3,17
    800011de:	06ee                	sll	a3,a3,0x1b
    800011e0:	412686b3          	sub	a3,a3,s2
    800011e4:	864a                	mv	a2,s2
    800011e6:	85ca                	mv	a1,s2
    800011e8:	8526                	mv	a0,s1
    800011ea:	00000097          	auipc	ra,0x0
    800011ee:	f38080e7          	jalr	-200(ra) # 80001122 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800011f2:	4729                	li	a4,10
    800011f4:	6685                	lui	a3,0x1
    800011f6:	00006617          	auipc	a2,0x6
    800011fa:	e0a60613          	add	a2,a2,-502 # 80007000 <_trampoline>
    800011fe:	040005b7          	lui	a1,0x4000
    80001202:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001204:	05b2                	sll	a1,a1,0xc
    80001206:	8526                	mv	a0,s1
    80001208:	00000097          	auipc	ra,0x0
    8000120c:	f1a080e7          	jalr	-230(ra) # 80001122 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001210:	8526                	mv	a0,s1
    80001212:	00000097          	auipc	ra,0x0
    80001216:	648080e7          	jalr	1608(ra) # 8000185a <proc_mapstacks>
}
    8000121a:	8526                	mv	a0,s1
    8000121c:	60e2                	ld	ra,24(sp)
    8000121e:	6442                	ld	s0,16(sp)
    80001220:	64a2                	ld	s1,8(sp)
    80001222:	6902                	ld	s2,0(sp)
    80001224:	6105                	add	sp,sp,32
    80001226:	8082                	ret

0000000080001228 <kvminit>:
{
    80001228:	1141                	add	sp,sp,-16
    8000122a:	e406                	sd	ra,8(sp)
    8000122c:	e022                	sd	s0,0(sp)
    8000122e:	0800                	add	s0,sp,16
  kernel_pagetable = kvmmake();
    80001230:	00000097          	auipc	ra,0x0
    80001234:	f22080e7          	jalr	-222(ra) # 80001152 <kvmmake>
    80001238:	00007797          	auipc	a5,0x7
    8000123c:	6aa7b423          	sd	a0,1704(a5) # 800088e0 <kernel_pagetable>
}
    80001240:	60a2                	ld	ra,8(sp)
    80001242:	6402                	ld	s0,0(sp)
    80001244:	0141                	add	sp,sp,16
    80001246:	8082                	ret

0000000080001248 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001248:	715d                	add	sp,sp,-80
    8000124a:	e486                	sd	ra,72(sp)
    8000124c:	e0a2                	sd	s0,64(sp)
    8000124e:	fc26                	sd	s1,56(sp)
    80001250:	f84a                	sd	s2,48(sp)
    80001252:	f44e                	sd	s3,40(sp)
    80001254:	f052                	sd	s4,32(sp)
    80001256:	ec56                	sd	s5,24(sp)
    80001258:	e85a                	sd	s6,16(sp)
    8000125a:	e45e                	sd	s7,8(sp)
    8000125c:	0880                	add	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000125e:	03459793          	sll	a5,a1,0x34
    80001262:	e795                	bnez	a5,8000128e <uvmunmap+0x46>
    80001264:	8a2a                	mv	s4,a0
    80001266:	892e                	mv	s2,a1
    80001268:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000126a:	0632                	sll	a2,a2,0xc
    8000126c:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001270:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001272:	6b05                	lui	s6,0x1
    80001274:	0735e263          	bltu	a1,s3,800012d8 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001278:	60a6                	ld	ra,72(sp)
    8000127a:	6406                	ld	s0,64(sp)
    8000127c:	74e2                	ld	s1,56(sp)
    8000127e:	7942                	ld	s2,48(sp)
    80001280:	79a2                	ld	s3,40(sp)
    80001282:	7a02                	ld	s4,32(sp)
    80001284:	6ae2                	ld	s5,24(sp)
    80001286:	6b42                	ld	s6,16(sp)
    80001288:	6ba2                	ld	s7,8(sp)
    8000128a:	6161                	add	sp,sp,80
    8000128c:	8082                	ret
    panic("uvmunmap: not aligned");
    8000128e:	00007517          	auipc	a0,0x7
    80001292:	e6250513          	add	a0,a0,-414 # 800080f0 <digits+0xb0>
    80001296:	fffff097          	auipc	ra,0xfffff
    8000129a:	2a6080e7          	jalr	678(ra) # 8000053c <panic>
      panic("uvmunmap: walk");
    8000129e:	00007517          	auipc	a0,0x7
    800012a2:	e6a50513          	add	a0,a0,-406 # 80008108 <digits+0xc8>
    800012a6:	fffff097          	auipc	ra,0xfffff
    800012aa:	296080e7          	jalr	662(ra) # 8000053c <panic>
      panic("uvmunmap: not mapped");
    800012ae:	00007517          	auipc	a0,0x7
    800012b2:	e6a50513          	add	a0,a0,-406 # 80008118 <digits+0xd8>
    800012b6:	fffff097          	auipc	ra,0xfffff
    800012ba:	286080e7          	jalr	646(ra) # 8000053c <panic>
      panic("uvmunmap: not a leaf");
    800012be:	00007517          	auipc	a0,0x7
    800012c2:	e7250513          	add	a0,a0,-398 # 80008130 <digits+0xf0>
    800012c6:	fffff097          	auipc	ra,0xfffff
    800012ca:	276080e7          	jalr	630(ra) # 8000053c <panic>
    *pte = 0;
    800012ce:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012d2:	995a                	add	s2,s2,s6
    800012d4:	fb3972e3          	bgeu	s2,s3,80001278 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012d8:	4601                	li	a2,0
    800012da:	85ca                	mv	a1,s2
    800012dc:	8552                	mv	a0,s4
    800012de:	00000097          	auipc	ra,0x0
    800012e2:	cd2080e7          	jalr	-814(ra) # 80000fb0 <walk>
    800012e6:	84aa                	mv	s1,a0
    800012e8:	d95d                	beqz	a0,8000129e <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800012ea:	6108                	ld	a0,0(a0)
    800012ec:	00157793          	and	a5,a0,1
    800012f0:	dfdd                	beqz	a5,800012ae <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800012f2:	3ff57793          	and	a5,a0,1023
    800012f6:	fd7784e3          	beq	a5,s7,800012be <uvmunmap+0x76>
    if(do_free){
    800012fa:	fc0a8ae3          	beqz	s5,800012ce <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800012fe:	8129                	srl	a0,a0,0xa
      kfree((void*)pa);
    80001300:	0532                	sll	a0,a0,0xc
    80001302:	fffff097          	auipc	ra,0xfffff
    80001306:	6e2080e7          	jalr	1762(ra) # 800009e4 <kfree>
    8000130a:	b7d1                	j	800012ce <uvmunmap+0x86>

000000008000130c <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000130c:	1101                	add	sp,sp,-32
    8000130e:	ec06                	sd	ra,24(sp)
    80001310:	e822                	sd	s0,16(sp)
    80001312:	e426                	sd	s1,8(sp)
    80001314:	1000                	add	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001316:	fffff097          	auipc	ra,0xfffff
    8000131a:	7cc080e7          	jalr	1996(ra) # 80000ae2 <kalloc>
    8000131e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001320:	c519                	beqz	a0,8000132e <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001322:	6605                	lui	a2,0x1
    80001324:	4581                	li	a1,0
    80001326:	00000097          	auipc	ra,0x0
    8000132a:	9a8080e7          	jalr	-1624(ra) # 80000cce <memset>
  return pagetable;
}
    8000132e:	8526                	mv	a0,s1
    80001330:	60e2                	ld	ra,24(sp)
    80001332:	6442                	ld	s0,16(sp)
    80001334:	64a2                	ld	s1,8(sp)
    80001336:	6105                	add	sp,sp,32
    80001338:	8082                	ret

000000008000133a <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    8000133a:	7179                	add	sp,sp,-48
    8000133c:	f406                	sd	ra,40(sp)
    8000133e:	f022                	sd	s0,32(sp)
    80001340:	ec26                	sd	s1,24(sp)
    80001342:	e84a                	sd	s2,16(sp)
    80001344:	e44e                	sd	s3,8(sp)
    80001346:	e052                	sd	s4,0(sp)
    80001348:	1800                	add	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000134a:	6785                	lui	a5,0x1
    8000134c:	04f67863          	bgeu	a2,a5,8000139c <uvmfirst+0x62>
    80001350:	8a2a                	mv	s4,a0
    80001352:	89ae                	mv	s3,a1
    80001354:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001356:	fffff097          	auipc	ra,0xfffff
    8000135a:	78c080e7          	jalr	1932(ra) # 80000ae2 <kalloc>
    8000135e:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001360:	6605                	lui	a2,0x1
    80001362:	4581                	li	a1,0
    80001364:	00000097          	auipc	ra,0x0
    80001368:	96a080e7          	jalr	-1686(ra) # 80000cce <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000136c:	4779                	li	a4,30
    8000136e:	86ca                	mv	a3,s2
    80001370:	6605                	lui	a2,0x1
    80001372:	4581                	li	a1,0
    80001374:	8552                	mv	a0,s4
    80001376:	00000097          	auipc	ra,0x0
    8000137a:	d22080e7          	jalr	-734(ra) # 80001098 <mappages>
  memmove(mem, src, sz);
    8000137e:	8626                	mv	a2,s1
    80001380:	85ce                	mv	a1,s3
    80001382:	854a                	mv	a0,s2
    80001384:	00000097          	auipc	ra,0x0
    80001388:	9a6080e7          	jalr	-1626(ra) # 80000d2a <memmove>
}
    8000138c:	70a2                	ld	ra,40(sp)
    8000138e:	7402                	ld	s0,32(sp)
    80001390:	64e2                	ld	s1,24(sp)
    80001392:	6942                	ld	s2,16(sp)
    80001394:	69a2                	ld	s3,8(sp)
    80001396:	6a02                	ld	s4,0(sp)
    80001398:	6145                	add	sp,sp,48
    8000139a:	8082                	ret
    panic("uvmfirst: more than a page");
    8000139c:	00007517          	auipc	a0,0x7
    800013a0:	dac50513          	add	a0,a0,-596 # 80008148 <digits+0x108>
    800013a4:	fffff097          	auipc	ra,0xfffff
    800013a8:	198080e7          	jalr	408(ra) # 8000053c <panic>

00000000800013ac <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013ac:	1101                	add	sp,sp,-32
    800013ae:	ec06                	sd	ra,24(sp)
    800013b0:	e822                	sd	s0,16(sp)
    800013b2:	e426                	sd	s1,8(sp)
    800013b4:	1000                	add	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013b6:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013b8:	00b67d63          	bgeu	a2,a1,800013d2 <uvmdealloc+0x26>
    800013bc:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013be:	6785                	lui	a5,0x1
    800013c0:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013c2:	00f60733          	add	a4,a2,a5
    800013c6:	76fd                	lui	a3,0xfffff
    800013c8:	8f75                	and	a4,a4,a3
    800013ca:	97ae                	add	a5,a5,a1
    800013cc:	8ff5                	and	a5,a5,a3
    800013ce:	00f76863          	bltu	a4,a5,800013de <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013d2:	8526                	mv	a0,s1
    800013d4:	60e2                	ld	ra,24(sp)
    800013d6:	6442                	ld	s0,16(sp)
    800013d8:	64a2                	ld	s1,8(sp)
    800013da:	6105                	add	sp,sp,32
    800013dc:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013de:	8f99                	sub	a5,a5,a4
    800013e0:	83b1                	srl	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013e2:	4685                	li	a3,1
    800013e4:	0007861b          	sext.w	a2,a5
    800013e8:	85ba                	mv	a1,a4
    800013ea:	00000097          	auipc	ra,0x0
    800013ee:	e5e080e7          	jalr	-418(ra) # 80001248 <uvmunmap>
    800013f2:	b7c5                	j	800013d2 <uvmdealloc+0x26>

00000000800013f4 <uvmalloc>:
  if(newsz < oldsz)
    800013f4:	0ab66563          	bltu	a2,a1,8000149e <uvmalloc+0xaa>
{
    800013f8:	7139                	add	sp,sp,-64
    800013fa:	fc06                	sd	ra,56(sp)
    800013fc:	f822                	sd	s0,48(sp)
    800013fe:	f426                	sd	s1,40(sp)
    80001400:	f04a                	sd	s2,32(sp)
    80001402:	ec4e                	sd	s3,24(sp)
    80001404:	e852                	sd	s4,16(sp)
    80001406:	e456                	sd	s5,8(sp)
    80001408:	e05a                	sd	s6,0(sp)
    8000140a:	0080                	add	s0,sp,64
    8000140c:	8aaa                	mv	s5,a0
    8000140e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001410:	6785                	lui	a5,0x1
    80001412:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001414:	95be                	add	a1,a1,a5
    80001416:	77fd                	lui	a5,0xfffff
    80001418:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000141c:	08c9f363          	bgeu	s3,a2,800014a2 <uvmalloc+0xae>
    80001420:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001422:	0126eb13          	or	s6,a3,18
    mem = kalloc();
    80001426:	fffff097          	auipc	ra,0xfffff
    8000142a:	6bc080e7          	jalr	1724(ra) # 80000ae2 <kalloc>
    8000142e:	84aa                	mv	s1,a0
    if(mem == 0){
    80001430:	c51d                	beqz	a0,8000145e <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001432:	6605                	lui	a2,0x1
    80001434:	4581                	li	a1,0
    80001436:	00000097          	auipc	ra,0x0
    8000143a:	898080e7          	jalr	-1896(ra) # 80000cce <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	875a                	mv	a4,s6
    80001440:	86a6                	mv	a3,s1
    80001442:	6605                	lui	a2,0x1
    80001444:	85ca                	mv	a1,s2
    80001446:	8556                	mv	a0,s5
    80001448:	00000097          	auipc	ra,0x0
    8000144c:	c50080e7          	jalr	-944(ra) # 80001098 <mappages>
    80001450:	e90d                	bnez	a0,80001482 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001452:	6785                	lui	a5,0x1
    80001454:	993e                	add	s2,s2,a5
    80001456:	fd4968e3          	bltu	s2,s4,80001426 <uvmalloc+0x32>
  return newsz;
    8000145a:	8552                	mv	a0,s4
    8000145c:	a809                	j	8000146e <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000145e:	864e                	mv	a2,s3
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	f48080e7          	jalr	-184(ra) # 800013ac <uvmdealloc>
      return 0;
    8000146c:	4501                	li	a0,0
}
    8000146e:	70e2                	ld	ra,56(sp)
    80001470:	7442                	ld	s0,48(sp)
    80001472:	74a2                	ld	s1,40(sp)
    80001474:	7902                	ld	s2,32(sp)
    80001476:	69e2                	ld	s3,24(sp)
    80001478:	6a42                	ld	s4,16(sp)
    8000147a:	6aa2                	ld	s5,8(sp)
    8000147c:	6b02                	ld	s6,0(sp)
    8000147e:	6121                	add	sp,sp,64
    80001480:	8082                	ret
      kfree(mem);
    80001482:	8526                	mv	a0,s1
    80001484:	fffff097          	auipc	ra,0xfffff
    80001488:	560080e7          	jalr	1376(ra) # 800009e4 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000148c:	864e                	mv	a2,s3
    8000148e:	85ca                	mv	a1,s2
    80001490:	8556                	mv	a0,s5
    80001492:	00000097          	auipc	ra,0x0
    80001496:	f1a080e7          	jalr	-230(ra) # 800013ac <uvmdealloc>
      return 0;
    8000149a:	4501                	li	a0,0
    8000149c:	bfc9                	j	8000146e <uvmalloc+0x7a>
    return oldsz;
    8000149e:	852e                	mv	a0,a1
}
    800014a0:	8082                	ret
  return newsz;
    800014a2:	8532                	mv	a0,a2
    800014a4:	b7e9                	j	8000146e <uvmalloc+0x7a>

00000000800014a6 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014a6:	7179                	add	sp,sp,-48
    800014a8:	f406                	sd	ra,40(sp)
    800014aa:	f022                	sd	s0,32(sp)
    800014ac:	ec26                	sd	s1,24(sp)
    800014ae:	e84a                	sd	s2,16(sp)
    800014b0:	e44e                	sd	s3,8(sp)
    800014b2:	e052                	sd	s4,0(sp)
    800014b4:	1800                	add	s0,sp,48
    800014b6:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014b8:	84aa                	mv	s1,a0
    800014ba:	6905                	lui	s2,0x1
    800014bc:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014be:	4985                	li	s3,1
    800014c0:	a829                	j	800014da <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014c2:	83a9                	srl	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014c4:	00c79513          	sll	a0,a5,0xc
    800014c8:	00000097          	auipc	ra,0x0
    800014cc:	fde080e7          	jalr	-34(ra) # 800014a6 <freewalk>
      pagetable[i] = 0;
    800014d0:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014d4:	04a1                	add	s1,s1,8
    800014d6:	03248163          	beq	s1,s2,800014f8 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014da:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014dc:	00f7f713          	and	a4,a5,15
    800014e0:	ff3701e3          	beq	a4,s3,800014c2 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014e4:	8b85                	and	a5,a5,1
    800014e6:	d7fd                	beqz	a5,800014d4 <freewalk+0x2e>
      panic("freewalk: leaf");
    800014e8:	00007517          	auipc	a0,0x7
    800014ec:	c8050513          	add	a0,a0,-896 # 80008168 <digits+0x128>
    800014f0:	fffff097          	auipc	ra,0xfffff
    800014f4:	04c080e7          	jalr	76(ra) # 8000053c <panic>
    }
  }
  kfree((void*)pagetable);
    800014f8:	8552                	mv	a0,s4
    800014fa:	fffff097          	auipc	ra,0xfffff
    800014fe:	4ea080e7          	jalr	1258(ra) # 800009e4 <kfree>
}
    80001502:	70a2                	ld	ra,40(sp)
    80001504:	7402                	ld	s0,32(sp)
    80001506:	64e2                	ld	s1,24(sp)
    80001508:	6942                	ld	s2,16(sp)
    8000150a:	69a2                	ld	s3,8(sp)
    8000150c:	6a02                	ld	s4,0(sp)
    8000150e:	6145                	add	sp,sp,48
    80001510:	8082                	ret

0000000080001512 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001512:	1101                	add	sp,sp,-32
    80001514:	ec06                	sd	ra,24(sp)
    80001516:	e822                	sd	s0,16(sp)
    80001518:	e426                	sd	s1,8(sp)
    8000151a:	1000                	add	s0,sp,32
    8000151c:	84aa                	mv	s1,a0
  if(sz > 0)
    8000151e:	e999                	bnez	a1,80001534 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001520:	8526                	mv	a0,s1
    80001522:	00000097          	auipc	ra,0x0
    80001526:	f84080e7          	jalr	-124(ra) # 800014a6 <freewalk>
}
    8000152a:	60e2                	ld	ra,24(sp)
    8000152c:	6442                	ld	s0,16(sp)
    8000152e:	64a2                	ld	s1,8(sp)
    80001530:	6105                	add	sp,sp,32
    80001532:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001534:	6785                	lui	a5,0x1
    80001536:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001538:	95be                	add	a1,a1,a5
    8000153a:	4685                	li	a3,1
    8000153c:	00c5d613          	srl	a2,a1,0xc
    80001540:	4581                	li	a1,0
    80001542:	00000097          	auipc	ra,0x0
    80001546:	d06080e7          	jalr	-762(ra) # 80001248 <uvmunmap>
    8000154a:	bfd9                	j	80001520 <uvmfree+0xe>

000000008000154c <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  // char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000154c:	ce59                	beqz	a2,800015ea <uvmcopy+0x9e>
{
    8000154e:	7179                	add	sp,sp,-48
    80001550:	f406                	sd	ra,40(sp)
    80001552:	f022                	sd	s0,32(sp)
    80001554:	ec26                	sd	s1,24(sp)
    80001556:	e84a                	sd	s2,16(sp)
    80001558:	e44e                	sd	s3,8(sp)
    8000155a:	e052                	sd	s4,0(sp)
    8000155c:	1800                	add	s0,sp,48
    8000155e:	8a2a                	mv	s4,a0
    80001560:	89ae                	mv	s3,a1
    80001562:	8932                	mv	s2,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001564:	4481                	li	s1,0
    if((pte = walk(old, i, 0)) == 0)
    80001566:	4601                	li	a2,0
    80001568:	85a6                	mv	a1,s1
    8000156a:	8552                	mv	a0,s4
    8000156c:	00000097          	auipc	ra,0x0
    80001570:	a44080e7          	jalr	-1468(ra) # 80000fb0 <walk>
    80001574:	c90d                	beqz	a0,800015a6 <uvmcopy+0x5a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001576:	6114                	ld	a3,0(a0)
    80001578:	0016f793          	and	a5,a3,1
    8000157c:	cf8d                	beqz	a5,800015b6 <uvmcopy+0x6a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);

    //Disable write on pte
    *pte = *pte & (~PTE_W); 
    8000157e:	ffb6f713          	and	a4,a3,-5
    80001582:	e118                	sd	a4,0(a0)
    pa = PTE2PA(*pte);
    80001584:	82a9                	srl	a3,a3,0xa
    
    flags = PTE_FLAGS(*pte);
    if(mappages(new, i, PGSIZE, (uint64)pa, flags) != 0){
    80001586:	3fb77713          	and	a4,a4,1019
    8000158a:	06b2                	sll	a3,a3,0xc
    8000158c:	6605                	lui	a2,0x1
    8000158e:	85a6                	mv	a1,s1
    80001590:	854e                	mv	a0,s3
    80001592:	00000097          	auipc	ra,0x0
    80001596:	b06080e7          	jalr	-1274(ra) # 80001098 <mappages>
    8000159a:	e515                	bnez	a0,800015c6 <uvmcopy+0x7a>
  for(i = 0; i < sz; i += PGSIZE){
    8000159c:	6785                	lui	a5,0x1
    8000159e:	94be                	add	s1,s1,a5
    800015a0:	fd24e3e3          	bltu	s1,s2,80001566 <uvmcopy+0x1a>
    800015a4:	a81d                	j	800015da <uvmcopy+0x8e>
      panic("uvmcopy: pte should exist");
    800015a6:	00007517          	auipc	a0,0x7
    800015aa:	bd250513          	add	a0,a0,-1070 # 80008178 <digits+0x138>
    800015ae:	fffff097          	auipc	ra,0xfffff
    800015b2:	f8e080e7          	jalr	-114(ra) # 8000053c <panic>
      panic("uvmcopy: page not present");
    800015b6:	00007517          	auipc	a0,0x7
    800015ba:	be250513          	add	a0,a0,-1054 # 80008198 <digits+0x158>
    800015be:	fffff097          	auipc	ra,0xfffff
    800015c2:	f7e080e7          	jalr	-130(ra) # 8000053c <panic>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015c6:	4685                	li	a3,1
    800015c8:	00c4d613          	srl	a2,s1,0xc
    800015cc:	4581                	li	a1,0
    800015ce:	854e                	mv	a0,s3
    800015d0:	00000097          	auipc	ra,0x0
    800015d4:	c78080e7          	jalr	-904(ra) # 80001248 <uvmunmap>
  return -1;
    800015d8:	557d                	li	a0,-1
}
    800015da:	70a2                	ld	ra,40(sp)
    800015dc:	7402                	ld	s0,32(sp)
    800015de:	64e2                	ld	s1,24(sp)
    800015e0:	6942                	ld	s2,16(sp)
    800015e2:	69a2                	ld	s3,8(sp)
    800015e4:	6a02                	ld	s4,0(sp)
    800015e6:	6145                	add	sp,sp,48
    800015e8:	8082                	ret
  return 0;
    800015ea:	4501                	li	a0,0
}
    800015ec:	8082                	ret

00000000800015ee <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800015ee:	1141                	add	sp,sp,-16
    800015f0:	e406                	sd	ra,8(sp)
    800015f2:	e022                	sd	s0,0(sp)
    800015f4:	0800                	add	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800015f6:	4601                	li	a2,0
    800015f8:	00000097          	auipc	ra,0x0
    800015fc:	9b8080e7          	jalr	-1608(ra) # 80000fb0 <walk>
  if(pte == 0)
    80001600:	c901                	beqz	a0,80001610 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001602:	611c                	ld	a5,0(a0)
    80001604:	9bbd                	and	a5,a5,-17
    80001606:	e11c                	sd	a5,0(a0)
}
    80001608:	60a2                	ld	ra,8(sp)
    8000160a:	6402                	ld	s0,0(sp)
    8000160c:	0141                	add	sp,sp,16
    8000160e:	8082                	ret
    panic("uvmclear");
    80001610:	00007517          	auipc	a0,0x7
    80001614:	ba850513          	add	a0,a0,-1112 # 800081b8 <digits+0x178>
    80001618:	fffff097          	auipc	ra,0xfffff
    8000161c:	f24080e7          	jalr	-220(ra) # 8000053c <panic>

0000000080001620 <copyout>:
// Return 0 on success, -1 on error.
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;
  while(len > 0){
    80001620:	cee1                	beqz	a3,800016f8 <copyout+0xd8>
{
    80001622:	7119                	add	sp,sp,-128
    80001624:	fc86                	sd	ra,120(sp)
    80001626:	f8a2                	sd	s0,112(sp)
    80001628:	f4a6                	sd	s1,104(sp)
    8000162a:	f0ca                	sd	s2,96(sp)
    8000162c:	ecce                	sd	s3,88(sp)
    8000162e:	e8d2                	sd	s4,80(sp)
    80001630:	e4d6                	sd	s5,72(sp)
    80001632:	e0da                	sd	s6,64(sp)
    80001634:	fc5e                	sd	s7,56(sp)
    80001636:	f862                	sd	s8,48(sp)
    80001638:	f466                	sd	s9,40(sp)
    8000163a:	f06a                	sd	s10,32(sp)
    8000163c:	ec6e                	sd	s11,24(sp)
    8000163e:	0100                	add	s0,sp,128
    80001640:	8c2a                	mv	s8,a0
    80001642:	8aae                	mv	s5,a1
    80001644:	8b32                	mv	s6,a2
    80001646:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(dstva);
    80001648:	7d7d                	lui	s10,0xfffff
    pa0 = walkaddr(pagetable, va0);

    if(pa0 == 0)
      return -1;

    n = PGSIZE - (dstva - va0);
    8000164a:	6b85                	lui	s7,0x1
    if(n > len)
      n = len;

    pte_t* pte = walk(pagetable, va0, 0);
    if (!(*pte & PTE_W)){
      printf("Hello?\n");
    8000164c:	00007d97          	auipc	s11,0x7
    80001650:	b7cd8d93          	add	s11,s11,-1156 # 800081c8 <digits+0x188>
    80001654:	a835                	j	80001690 <copyout+0x70>
    pte_t* pte = walk(pagetable, va0, 0);
    80001656:	4601                	li	a2,0
    80001658:	85ce                	mv	a1,s3
    8000165a:	8562                	mv	a0,s8
    8000165c:	00000097          	auipc	ra,0x0
    80001660:	954080e7          	jalr	-1708(ra) # 80000fb0 <walk>
    80001664:	8caa                	mv	s9,a0
    if (!(*pte & PTE_W)){
    80001666:	611c                	ld	a5,0(a0)
    80001668:	8b91                	and	a5,a5,4
    8000166a:	c7a1                	beqz	a5,800016b2 <copyout+0x92>
      flags |= PTE_W;  
      char * mem = kalloc();
      memmove(mem, (char*) pa0, PGSIZE);
      mappages(pagetable, va0, PGSIZE, (uint64)mem, flags);
    }
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000166c:	01548533          	add	a0,s1,s5
    80001670:	0009061b          	sext.w	a2,s2
    80001674:	85da                	mv	a1,s6
    80001676:	41350533          	sub	a0,a0,s3
    8000167a:	fffff097          	auipc	ra,0xfffff
    8000167e:	6b0080e7          	jalr	1712(ra) # 80000d2a <memmove>

    len -= n;
    80001682:	412a0a33          	sub	s4,s4,s2
    src += n;
    80001686:	9b4a                	add	s6,s6,s2
    dstva = va0 + PGSIZE;
    80001688:	01798ab3          	add	s5,s3,s7
  while(len > 0){
    8000168c:	060a0463          	beqz	s4,800016f4 <copyout+0xd4>
    va0 = PGROUNDDOWN(dstva);
    80001690:	01aaf9b3          	and	s3,s5,s10
    pa0 = walkaddr(pagetable, va0);
    80001694:	85ce                	mv	a1,s3
    80001696:	8562                	mv	a0,s8
    80001698:	00000097          	auipc	ra,0x0
    8000169c:	9be080e7          	jalr	-1602(ra) # 80001056 <walkaddr>
    800016a0:	84aa                	mv	s1,a0
    if(pa0 == 0)
    800016a2:	cd29                	beqz	a0,800016fc <copyout+0xdc>
    n = PGSIZE - (dstva - va0);
    800016a4:	41598933          	sub	s2,s3,s5
    800016a8:	995e                	add	s2,s2,s7
    800016aa:	fb2a76e3          	bgeu	s4,s2,80001656 <copyout+0x36>
    800016ae:	8952                	mv	s2,s4
    800016b0:	b75d                	j	80001656 <copyout+0x36>
      printf("Hello?\n");
    800016b2:	856e                	mv	a0,s11
    800016b4:	fffff097          	auipc	ra,0xfffff
    800016b8:	ed2080e7          	jalr	-302(ra) # 80000586 <printf>
      uint flags= PTE_FLAGS(*pte);
    800016bc:	000cbc83          	ld	s9,0(s9)
    800016c0:	3ffcfc93          	and	s9,s9,1023
      char * mem = kalloc();
    800016c4:	fffff097          	auipc	ra,0xfffff
    800016c8:	41e080e7          	jalr	1054(ra) # 80000ae2 <kalloc>
    800016cc:	f8a43423          	sd	a0,-120(s0)
      memmove(mem, (char*) pa0, PGSIZE);
    800016d0:	865e                	mv	a2,s7
    800016d2:	85a6                	mv	a1,s1
    800016d4:	fffff097          	auipc	ra,0xfffff
    800016d8:	656080e7          	jalr	1622(ra) # 80000d2a <memmove>
      mappages(pagetable, va0, PGSIZE, (uint64)mem, flags);
    800016dc:	004ce713          	or	a4,s9,4
    800016e0:	f8843683          	ld	a3,-120(s0)
    800016e4:	865e                	mv	a2,s7
    800016e6:	85ce                	mv	a1,s3
    800016e8:	8562                	mv	a0,s8
    800016ea:	00000097          	auipc	ra,0x0
    800016ee:	9ae080e7          	jalr	-1618(ra) # 80001098 <mappages>
    800016f2:	bfad                	j	8000166c <copyout+0x4c>
  }
  return 0;
    800016f4:	4501                	li	a0,0
    800016f6:	a021                	j	800016fe <copyout+0xde>
    800016f8:	4501                	li	a0,0
}
    800016fa:	8082                	ret
      return -1;
    800016fc:	557d                	li	a0,-1
}
    800016fe:	70e6                	ld	ra,120(sp)
    80001700:	7446                	ld	s0,112(sp)
    80001702:	74a6                	ld	s1,104(sp)
    80001704:	7906                	ld	s2,96(sp)
    80001706:	69e6                	ld	s3,88(sp)
    80001708:	6a46                	ld	s4,80(sp)
    8000170a:	6aa6                	ld	s5,72(sp)
    8000170c:	6b06                	ld	s6,64(sp)
    8000170e:	7be2                	ld	s7,56(sp)
    80001710:	7c42                	ld	s8,48(sp)
    80001712:	7ca2                	ld	s9,40(sp)
    80001714:	7d02                	ld	s10,32(sp)
    80001716:	6de2                	ld	s11,24(sp)
    80001718:	6109                	add	sp,sp,128
    8000171a:	8082                	ret

000000008000171c <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000171c:	caa5                	beqz	a3,8000178c <copyin+0x70>
{
    8000171e:	715d                	add	sp,sp,-80
    80001720:	e486                	sd	ra,72(sp)
    80001722:	e0a2                	sd	s0,64(sp)
    80001724:	fc26                	sd	s1,56(sp)
    80001726:	f84a                	sd	s2,48(sp)
    80001728:	f44e                	sd	s3,40(sp)
    8000172a:	f052                	sd	s4,32(sp)
    8000172c:	ec56                	sd	s5,24(sp)
    8000172e:	e85a                	sd	s6,16(sp)
    80001730:	e45e                	sd	s7,8(sp)
    80001732:	e062                	sd	s8,0(sp)
    80001734:	0880                	add	s0,sp,80
    80001736:	8b2a                	mv	s6,a0
    80001738:	8a2e                	mv	s4,a1
    8000173a:	8c32                	mv	s8,a2
    8000173c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000173e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001740:	6a85                	lui	s5,0x1
    80001742:	a01d                	j	80001768 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001744:	018505b3          	add	a1,a0,s8
    80001748:	0004861b          	sext.w	a2,s1
    8000174c:	412585b3          	sub	a1,a1,s2
    80001750:	8552                	mv	a0,s4
    80001752:	fffff097          	auipc	ra,0xfffff
    80001756:	5d8080e7          	jalr	1496(ra) # 80000d2a <memmove>

    len -= n;
    8000175a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000175e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001760:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001764:	02098263          	beqz	s3,80001788 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001768:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000176c:	85ca                	mv	a1,s2
    8000176e:	855a                	mv	a0,s6
    80001770:	00000097          	auipc	ra,0x0
    80001774:	8e6080e7          	jalr	-1818(ra) # 80001056 <walkaddr>
    if(pa0 == 0)
    80001778:	cd01                	beqz	a0,80001790 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000177a:	418904b3          	sub	s1,s2,s8
    8000177e:	94d6                	add	s1,s1,s5
    80001780:	fc99f2e3          	bgeu	s3,s1,80001744 <copyin+0x28>
    80001784:	84ce                	mv	s1,s3
    80001786:	bf7d                	j	80001744 <copyin+0x28>
  }
  return 0;
    80001788:	4501                	li	a0,0
    8000178a:	a021                	j	80001792 <copyin+0x76>
    8000178c:	4501                	li	a0,0
}
    8000178e:	8082                	ret
      return -1;
    80001790:	557d                	li	a0,-1
}
    80001792:	60a6                	ld	ra,72(sp)
    80001794:	6406                	ld	s0,64(sp)
    80001796:	74e2                	ld	s1,56(sp)
    80001798:	7942                	ld	s2,48(sp)
    8000179a:	79a2                	ld	s3,40(sp)
    8000179c:	7a02                	ld	s4,32(sp)
    8000179e:	6ae2                	ld	s5,24(sp)
    800017a0:	6b42                	ld	s6,16(sp)
    800017a2:	6ba2                	ld	s7,8(sp)
    800017a4:	6c02                	ld	s8,0(sp)
    800017a6:	6161                	add	sp,sp,80
    800017a8:	8082                	ret

00000000800017aa <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017aa:	c2dd                	beqz	a3,80001850 <copyinstr+0xa6>
{
    800017ac:	715d                	add	sp,sp,-80
    800017ae:	e486                	sd	ra,72(sp)
    800017b0:	e0a2                	sd	s0,64(sp)
    800017b2:	fc26                	sd	s1,56(sp)
    800017b4:	f84a                	sd	s2,48(sp)
    800017b6:	f44e                	sd	s3,40(sp)
    800017b8:	f052                	sd	s4,32(sp)
    800017ba:	ec56                	sd	s5,24(sp)
    800017bc:	e85a                	sd	s6,16(sp)
    800017be:	e45e                	sd	s7,8(sp)
    800017c0:	0880                	add	s0,sp,80
    800017c2:	8a2a                	mv	s4,a0
    800017c4:	8b2e                	mv	s6,a1
    800017c6:	8bb2                	mv	s7,a2
    800017c8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017ca:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017cc:	6985                	lui	s3,0x1
    800017ce:	a02d                	j	800017f8 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017d0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017d4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017d6:	37fd                	addw	a5,a5,-1
    800017d8:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017dc:	60a6                	ld	ra,72(sp)
    800017de:	6406                	ld	s0,64(sp)
    800017e0:	74e2                	ld	s1,56(sp)
    800017e2:	7942                	ld	s2,48(sp)
    800017e4:	79a2                	ld	s3,40(sp)
    800017e6:	7a02                	ld	s4,32(sp)
    800017e8:	6ae2                	ld	s5,24(sp)
    800017ea:	6b42                	ld	s6,16(sp)
    800017ec:	6ba2                	ld	s7,8(sp)
    800017ee:	6161                	add	sp,sp,80
    800017f0:	8082                	ret
    srcva = va0 + PGSIZE;
    800017f2:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017f6:	c8a9                	beqz	s1,80001848 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017f8:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017fc:	85ca                	mv	a1,s2
    800017fe:	8552                	mv	a0,s4
    80001800:	00000097          	auipc	ra,0x0
    80001804:	856080e7          	jalr	-1962(ra) # 80001056 <walkaddr>
    if(pa0 == 0)
    80001808:	c131                	beqz	a0,8000184c <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    8000180a:	417906b3          	sub	a3,s2,s7
    8000180e:	96ce                	add	a3,a3,s3
    80001810:	00d4f363          	bgeu	s1,a3,80001816 <copyinstr+0x6c>
    80001814:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001816:	955e                	add	a0,a0,s7
    80001818:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000181c:	daf9                	beqz	a3,800017f2 <copyinstr+0x48>
    8000181e:	87da                	mv	a5,s6
    80001820:	885a                	mv	a6,s6
      if(*p == '\0'){
    80001822:	41650633          	sub	a2,a0,s6
    while(n > 0){
    80001826:	96da                	add	a3,a3,s6
    80001828:	85be                	mv	a1,a5
      if(*p == '\0'){
    8000182a:	00f60733          	add	a4,a2,a5
    8000182e:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdca90>
    80001832:	df59                	beqz	a4,800017d0 <copyinstr+0x26>
        *dst = *p;
    80001834:	00e78023          	sb	a4,0(a5)
      dst++;
    80001838:	0785                	add	a5,a5,1
    while(n > 0){
    8000183a:	fed797e3          	bne	a5,a3,80001828 <copyinstr+0x7e>
    8000183e:	14fd                	add	s1,s1,-1
    80001840:	94c2                	add	s1,s1,a6
      --max;
    80001842:	8c8d                	sub	s1,s1,a1
      dst++;
    80001844:	8b3e                	mv	s6,a5
    80001846:	b775                	j	800017f2 <copyinstr+0x48>
    80001848:	4781                	li	a5,0
    8000184a:	b771                	j	800017d6 <copyinstr+0x2c>
      return -1;
    8000184c:	557d                	li	a0,-1
    8000184e:	b779                	j	800017dc <copyinstr+0x32>
  int got_null = 0;
    80001850:	4781                	li	a5,0
  if(got_null){
    80001852:	37fd                	addw	a5,a5,-1
    80001854:	0007851b          	sext.w	a0,a5
}
    80001858:	8082                	ret

000000008000185a <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    8000185a:	7139                	add	sp,sp,-64
    8000185c:	fc06                	sd	ra,56(sp)
    8000185e:	f822                	sd	s0,48(sp)
    80001860:	f426                	sd	s1,40(sp)
    80001862:	f04a                	sd	s2,32(sp)
    80001864:	ec4e                	sd	s3,24(sp)
    80001866:	e852                	sd	s4,16(sp)
    80001868:	e456                	sd	s5,8(sp)
    8000186a:	e05a                	sd	s6,0(sp)
    8000186c:	0080                	add	s0,sp,64
    8000186e:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001870:	0000f497          	auipc	s1,0xf
    80001874:	72048493          	add	s1,s1,1824 # 80010f90 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001878:	8b26                	mv	s6,s1
    8000187a:	00006a97          	auipc	s5,0x6
    8000187e:	786a8a93          	add	s5,s5,1926 # 80008000 <etext>
    80001882:	04000937          	lui	s2,0x4000
    80001886:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001888:	0932                	sll	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    8000188a:	00016a17          	auipc	s4,0x16
    8000188e:	906a0a13          	add	s4,s4,-1786 # 80017190 <tickslock>
    char *pa = kalloc();
    80001892:	fffff097          	auipc	ra,0xfffff
    80001896:	250080e7          	jalr	592(ra) # 80000ae2 <kalloc>
    8000189a:	862a                	mv	a2,a0
    if (pa == 0)
    8000189c:	c131                	beqz	a0,800018e0 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    8000189e:	416485b3          	sub	a1,s1,s6
    800018a2:	858d                	sra	a1,a1,0x3
    800018a4:	000ab783          	ld	a5,0(s5)
    800018a8:	02f585b3          	mul	a1,a1,a5
    800018ac:	2585                	addw	a1,a1,1
    800018ae:	00d5959b          	sllw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018b2:	4719                	li	a4,6
    800018b4:	6685                	lui	a3,0x1
    800018b6:	40b905b3          	sub	a1,s2,a1
    800018ba:	854e                	mv	a0,s3
    800018bc:	00000097          	auipc	ra,0x0
    800018c0:	866080e7          	jalr	-1946(ra) # 80001122 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018c4:	18848493          	add	s1,s1,392
    800018c8:	fd4495e3          	bne	s1,s4,80001892 <proc_mapstacks+0x38>
  }
}
    800018cc:	70e2                	ld	ra,56(sp)
    800018ce:	7442                	ld	s0,48(sp)
    800018d0:	74a2                	ld	s1,40(sp)
    800018d2:	7902                	ld	s2,32(sp)
    800018d4:	69e2                	ld	s3,24(sp)
    800018d6:	6a42                	ld	s4,16(sp)
    800018d8:	6aa2                	ld	s5,8(sp)
    800018da:	6b02                	ld	s6,0(sp)
    800018dc:	6121                	add	sp,sp,64
    800018de:	8082                	ret
      panic("kalloc");
    800018e0:	00007517          	auipc	a0,0x7
    800018e4:	8f050513          	add	a0,a0,-1808 # 800081d0 <digits+0x190>
    800018e8:	fffff097          	auipc	ra,0xfffff
    800018ec:	c54080e7          	jalr	-940(ra) # 8000053c <panic>

00000000800018f0 <procinit>:

// initialize the proc table.
void procinit(void)
{
    800018f0:	7139                	add	sp,sp,-64
    800018f2:	fc06                	sd	ra,56(sp)
    800018f4:	f822                	sd	s0,48(sp)
    800018f6:	f426                	sd	s1,40(sp)
    800018f8:	f04a                	sd	s2,32(sp)
    800018fa:	ec4e                	sd	s3,24(sp)
    800018fc:	e852                	sd	s4,16(sp)
    800018fe:	e456                	sd	s5,8(sp)
    80001900:	e05a                	sd	s6,0(sp)
    80001902:	0080                	add	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001904:	00007597          	auipc	a1,0x7
    80001908:	8d458593          	add	a1,a1,-1836 # 800081d8 <digits+0x198>
    8000190c:	0000f517          	auipc	a0,0xf
    80001910:	25450513          	add	a0,a0,596 # 80010b60 <pid_lock>
    80001914:	fffff097          	auipc	ra,0xfffff
    80001918:	22e080e7          	jalr	558(ra) # 80000b42 <initlock>
  initlock(&wait_lock, "wait_lock");
    8000191c:	00007597          	auipc	a1,0x7
    80001920:	8c458593          	add	a1,a1,-1852 # 800081e0 <digits+0x1a0>
    80001924:	0000f517          	auipc	a0,0xf
    80001928:	25450513          	add	a0,a0,596 # 80010b78 <wait_lock>
    8000192c:	fffff097          	auipc	ra,0xfffff
    80001930:	216080e7          	jalr	534(ra) # 80000b42 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001934:	0000f497          	auipc	s1,0xf
    80001938:	65c48493          	add	s1,s1,1628 # 80010f90 <proc>
  {
    initlock(&p->lock, "proc");
    8000193c:	00007b17          	auipc	s6,0x7
    80001940:	8b4b0b13          	add	s6,s6,-1868 # 800081f0 <digits+0x1b0>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001944:	8aa6                	mv	s5,s1
    80001946:	00006a17          	auipc	s4,0x6
    8000194a:	6baa0a13          	add	s4,s4,1722 # 80008000 <etext>
    8000194e:	04000937          	lui	s2,0x4000
    80001952:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001954:	0932                	sll	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001956:	00016997          	auipc	s3,0x16
    8000195a:	83a98993          	add	s3,s3,-1990 # 80017190 <tickslock>
    initlock(&p->lock, "proc");
    8000195e:	85da                	mv	a1,s6
    80001960:	8526                	mv	a0,s1
    80001962:	fffff097          	auipc	ra,0xfffff
    80001966:	1e0080e7          	jalr	480(ra) # 80000b42 <initlock>
    p->state = UNUSED;
    8000196a:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    8000196e:	415487b3          	sub	a5,s1,s5
    80001972:	878d                	sra	a5,a5,0x3
    80001974:	000a3703          	ld	a4,0(s4)
    80001978:	02e787b3          	mul	a5,a5,a4
    8000197c:	2785                	addw	a5,a5,1
    8000197e:	00d7979b          	sllw	a5,a5,0xd
    80001982:	40f907b3          	sub	a5,s2,a5
    80001986:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001988:	18848493          	add	s1,s1,392
    8000198c:	fd3499e3          	bne	s1,s3,8000195e <procinit+0x6e>
  }
}
    80001990:	70e2                	ld	ra,56(sp)
    80001992:	7442                	ld	s0,48(sp)
    80001994:	74a2                	ld	s1,40(sp)
    80001996:	7902                	ld	s2,32(sp)
    80001998:	69e2                	ld	s3,24(sp)
    8000199a:	6a42                	ld	s4,16(sp)
    8000199c:	6aa2                	ld	s5,8(sp)
    8000199e:	6b02                	ld	s6,0(sp)
    800019a0:	6121                	add	sp,sp,64
    800019a2:	8082                	ret

00000000800019a4 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    800019a4:	1141                	add	sp,sp,-16
    800019a6:	e422                	sd	s0,8(sp)
    800019a8:	0800                	add	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019aa:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019ac:	2501                	sext.w	a0,a0
    800019ae:	6422                	ld	s0,8(sp)
    800019b0:	0141                	add	sp,sp,16
    800019b2:	8082                	ret

00000000800019b4 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    800019b4:	1141                	add	sp,sp,-16
    800019b6:	e422                	sd	s0,8(sp)
    800019b8:	0800                	add	s0,sp,16
    800019ba:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019bc:	2781                	sext.w	a5,a5
    800019be:	079e                	sll	a5,a5,0x7
  return c;
}
    800019c0:	0000f517          	auipc	a0,0xf
    800019c4:	1d050513          	add	a0,a0,464 # 80010b90 <cpus>
    800019c8:	953e                	add	a0,a0,a5
    800019ca:	6422                	ld	s0,8(sp)
    800019cc:	0141                	add	sp,sp,16
    800019ce:	8082                	ret

00000000800019d0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019d0:	1101                	add	sp,sp,-32
    800019d2:	ec06                	sd	ra,24(sp)
    800019d4:	e822                	sd	s0,16(sp)
    800019d6:	e426                	sd	s1,8(sp)
    800019d8:	1000                	add	s0,sp,32
  push_off();
    800019da:	fffff097          	auipc	ra,0xfffff
    800019de:	1ac080e7          	jalr	428(ra) # 80000b86 <push_off>
    800019e2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019e4:	2781                	sext.w	a5,a5
    800019e6:	079e                	sll	a5,a5,0x7
    800019e8:	0000f717          	auipc	a4,0xf
    800019ec:	17870713          	add	a4,a4,376 # 80010b60 <pid_lock>
    800019f0:	97ba                	add	a5,a5,a4
    800019f2:	7b84                	ld	s1,48(a5)
  pop_off();
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	232080e7          	jalr	562(ra) # 80000c26 <pop_off>
  return p;
}
    800019fc:	8526                	mv	a0,s1
    800019fe:	60e2                	ld	ra,24(sp)
    80001a00:	6442                	ld	s0,16(sp)
    80001a02:	64a2                	ld	s1,8(sp)
    80001a04:	6105                	add	sp,sp,32
    80001a06:	8082                	ret

0000000080001a08 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001a08:	1141                	add	sp,sp,-16
    80001a0a:	e406                	sd	ra,8(sp)
    80001a0c:	e022                	sd	s0,0(sp)
    80001a0e:	0800                	add	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a10:	00000097          	auipc	ra,0x0
    80001a14:	fc0080e7          	jalr	-64(ra) # 800019d0 <myproc>
    80001a18:	fffff097          	auipc	ra,0xfffff
    80001a1c:	26e080e7          	jalr	622(ra) # 80000c86 <release>

  if (first)
    80001a20:	00007797          	auipc	a5,0x7
    80001a24:	e507a783          	lw	a5,-432(a5) # 80008870 <first.1>
    80001a28:	eb89                	bnez	a5,80001a3a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a2a:	00001097          	auipc	ra,0x1
    80001a2e:	fec080e7          	jalr	-20(ra) # 80002a16 <usertrapret>
}
    80001a32:	60a2                	ld	ra,8(sp)
    80001a34:	6402                	ld	s0,0(sp)
    80001a36:	0141                	add	sp,sp,16
    80001a38:	8082                	ret
    first = 0;
    80001a3a:	00007797          	auipc	a5,0x7
    80001a3e:	e207ab23          	sw	zero,-458(a5) # 80008870 <first.1>
    fsinit(ROOTDEV);
    80001a42:	4505                	li	a0,1
    80001a44:	00002097          	auipc	ra,0x2
    80001a48:	efc080e7          	jalr	-260(ra) # 80003940 <fsinit>
    80001a4c:	bff9                	j	80001a2a <forkret+0x22>

0000000080001a4e <allocpid>:
{
    80001a4e:	1101                	add	sp,sp,-32
    80001a50:	ec06                	sd	ra,24(sp)
    80001a52:	e822                	sd	s0,16(sp)
    80001a54:	e426                	sd	s1,8(sp)
    80001a56:	e04a                	sd	s2,0(sp)
    80001a58:	1000                	add	s0,sp,32
  acquire(&pid_lock);
    80001a5a:	0000f917          	auipc	s2,0xf
    80001a5e:	10690913          	add	s2,s2,262 # 80010b60 <pid_lock>
    80001a62:	854a                	mv	a0,s2
    80001a64:	fffff097          	auipc	ra,0xfffff
    80001a68:	16e080e7          	jalr	366(ra) # 80000bd2 <acquire>
  pid = nextpid;
    80001a6c:	00007797          	auipc	a5,0x7
    80001a70:	e0878793          	add	a5,a5,-504 # 80008874 <nextpid>
    80001a74:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a76:	0014871b          	addw	a4,s1,1
    80001a7a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a7c:	854a                	mv	a0,s2
    80001a7e:	fffff097          	auipc	ra,0xfffff
    80001a82:	208080e7          	jalr	520(ra) # 80000c86 <release>
}
    80001a86:	8526                	mv	a0,s1
    80001a88:	60e2                	ld	ra,24(sp)
    80001a8a:	6442                	ld	s0,16(sp)
    80001a8c:	64a2                	ld	s1,8(sp)
    80001a8e:	6902                	ld	s2,0(sp)
    80001a90:	6105                	add	sp,sp,32
    80001a92:	8082                	ret

0000000080001a94 <proc_pagetable>:
{
    80001a94:	1101                	add	sp,sp,-32
    80001a96:	ec06                	sd	ra,24(sp)
    80001a98:	e822                	sd	s0,16(sp)
    80001a9a:	e426                	sd	s1,8(sp)
    80001a9c:	e04a                	sd	s2,0(sp)
    80001a9e:	1000                	add	s0,sp,32
    80001aa0:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001aa2:	00000097          	auipc	ra,0x0
    80001aa6:	86a080e7          	jalr	-1942(ra) # 8000130c <uvmcreate>
    80001aaa:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001aac:	c121                	beqz	a0,80001aec <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aae:	4729                	li	a4,10
    80001ab0:	00005697          	auipc	a3,0x5
    80001ab4:	55068693          	add	a3,a3,1360 # 80007000 <_trampoline>
    80001ab8:	6605                	lui	a2,0x1
    80001aba:	040005b7          	lui	a1,0x4000
    80001abe:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ac0:	05b2                	sll	a1,a1,0xc
    80001ac2:	fffff097          	auipc	ra,0xfffff
    80001ac6:	5d6080e7          	jalr	1494(ra) # 80001098 <mappages>
    80001aca:	02054863          	bltz	a0,80001afa <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ace:	4719                	li	a4,6
    80001ad0:	05893683          	ld	a3,88(s2)
    80001ad4:	6605                	lui	a2,0x1
    80001ad6:	020005b7          	lui	a1,0x2000
    80001ada:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001adc:	05b6                	sll	a1,a1,0xd
    80001ade:	8526                	mv	a0,s1
    80001ae0:	fffff097          	auipc	ra,0xfffff
    80001ae4:	5b8080e7          	jalr	1464(ra) # 80001098 <mappages>
    80001ae8:	02054163          	bltz	a0,80001b0a <proc_pagetable+0x76>
}
    80001aec:	8526                	mv	a0,s1
    80001aee:	60e2                	ld	ra,24(sp)
    80001af0:	6442                	ld	s0,16(sp)
    80001af2:	64a2                	ld	s1,8(sp)
    80001af4:	6902                	ld	s2,0(sp)
    80001af6:	6105                	add	sp,sp,32
    80001af8:	8082                	ret
    uvmfree(pagetable, 0);
    80001afa:	4581                	li	a1,0
    80001afc:	8526                	mv	a0,s1
    80001afe:	00000097          	auipc	ra,0x0
    80001b02:	a14080e7          	jalr	-1516(ra) # 80001512 <uvmfree>
    return 0;
    80001b06:	4481                	li	s1,0
    80001b08:	b7d5                	j	80001aec <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b0a:	4681                	li	a3,0
    80001b0c:	4605                	li	a2,1
    80001b0e:	040005b7          	lui	a1,0x4000
    80001b12:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b14:	05b2                	sll	a1,a1,0xc
    80001b16:	8526                	mv	a0,s1
    80001b18:	fffff097          	auipc	ra,0xfffff
    80001b1c:	730080e7          	jalr	1840(ra) # 80001248 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b20:	4581                	li	a1,0
    80001b22:	8526                	mv	a0,s1
    80001b24:	00000097          	auipc	ra,0x0
    80001b28:	9ee080e7          	jalr	-1554(ra) # 80001512 <uvmfree>
    return 0;
    80001b2c:	4481                	li	s1,0
    80001b2e:	bf7d                	j	80001aec <proc_pagetable+0x58>

0000000080001b30 <proc_freepagetable>:
{
    80001b30:	1101                	add	sp,sp,-32
    80001b32:	ec06                	sd	ra,24(sp)
    80001b34:	e822                	sd	s0,16(sp)
    80001b36:	e426                	sd	s1,8(sp)
    80001b38:	e04a                	sd	s2,0(sp)
    80001b3a:	1000                	add	s0,sp,32
    80001b3c:	84aa                	mv	s1,a0
    80001b3e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b40:	4681                	li	a3,0
    80001b42:	4605                	li	a2,1
    80001b44:	040005b7          	lui	a1,0x4000
    80001b48:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b4a:	05b2                	sll	a1,a1,0xc
    80001b4c:	fffff097          	auipc	ra,0xfffff
    80001b50:	6fc080e7          	jalr	1788(ra) # 80001248 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b54:	4681                	li	a3,0
    80001b56:	4605                	li	a2,1
    80001b58:	020005b7          	lui	a1,0x2000
    80001b5c:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b5e:	05b6                	sll	a1,a1,0xd
    80001b60:	8526                	mv	a0,s1
    80001b62:	fffff097          	auipc	ra,0xfffff
    80001b66:	6e6080e7          	jalr	1766(ra) # 80001248 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b6a:	85ca                	mv	a1,s2
    80001b6c:	8526                	mv	a0,s1
    80001b6e:	00000097          	auipc	ra,0x0
    80001b72:	9a4080e7          	jalr	-1628(ra) # 80001512 <uvmfree>
}
    80001b76:	60e2                	ld	ra,24(sp)
    80001b78:	6442                	ld	s0,16(sp)
    80001b7a:	64a2                	ld	s1,8(sp)
    80001b7c:	6902                	ld	s2,0(sp)
    80001b7e:	6105                	add	sp,sp,32
    80001b80:	8082                	ret

0000000080001b82 <freeproc>:
{
    80001b82:	1101                	add	sp,sp,-32
    80001b84:	ec06                	sd	ra,24(sp)
    80001b86:	e822                	sd	s0,16(sp)
    80001b88:	e426                	sd	s1,8(sp)
    80001b8a:	1000                	add	s0,sp,32
    80001b8c:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b8e:	6d28                	ld	a0,88(a0)
    80001b90:	c509                	beqz	a0,80001b9a <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b92:	fffff097          	auipc	ra,0xfffff
    80001b96:	e52080e7          	jalr	-430(ra) # 800009e4 <kfree>
  p->trapframe = 0;
    80001b9a:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001b9e:	68a8                	ld	a0,80(s1)
    80001ba0:	c511                	beqz	a0,80001bac <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001ba2:	64ac                	ld	a1,72(s1)
    80001ba4:	00000097          	auipc	ra,0x0
    80001ba8:	f8c080e7          	jalr	-116(ra) # 80001b30 <proc_freepagetable>
  p->pagetable = 0;
    80001bac:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bb0:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bb4:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bb8:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bbc:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bc0:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bc4:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bc8:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bcc:	0004ac23          	sw	zero,24(s1)
}
    80001bd0:	60e2                	ld	ra,24(sp)
    80001bd2:	6442                	ld	s0,16(sp)
    80001bd4:	64a2                	ld	s1,8(sp)
    80001bd6:	6105                	add	sp,sp,32
    80001bd8:	8082                	ret

0000000080001bda <allocproc>:
{
    80001bda:	1101                	add	sp,sp,-32
    80001bdc:	ec06                	sd	ra,24(sp)
    80001bde:	e822                	sd	s0,16(sp)
    80001be0:	e426                	sd	s1,8(sp)
    80001be2:	e04a                	sd	s2,0(sp)
    80001be4:	1000                	add	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001be6:	0000f497          	auipc	s1,0xf
    80001bea:	3aa48493          	add	s1,s1,938 # 80010f90 <proc>
    80001bee:	00015917          	auipc	s2,0x15
    80001bf2:	5a290913          	add	s2,s2,1442 # 80017190 <tickslock>
    acquire(&p->lock);
    80001bf6:	8526                	mv	a0,s1
    80001bf8:	fffff097          	auipc	ra,0xfffff
    80001bfc:	fda080e7          	jalr	-38(ra) # 80000bd2 <acquire>
    if (p->state == UNUSED)
    80001c00:	4c9c                	lw	a5,24(s1)
    80001c02:	cf81                	beqz	a5,80001c1a <allocproc+0x40>
      release(&p->lock);
    80001c04:	8526                	mv	a0,s1
    80001c06:	fffff097          	auipc	ra,0xfffff
    80001c0a:	080080e7          	jalr	128(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001c0e:	18848493          	add	s1,s1,392
    80001c12:	ff2492e3          	bne	s1,s2,80001bf6 <allocproc+0x1c>
  return 0;
    80001c16:	4481                	li	s1,0
    80001c18:	a8ad                	j	80001c92 <allocproc+0xb8>
  p->pid = allocpid();
    80001c1a:	00000097          	auipc	ra,0x0
    80001c1e:	e34080e7          	jalr	-460(ra) # 80001a4e <allocpid>
    80001c22:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c24:	4785                	li	a5,1
    80001c26:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c28:	fffff097          	auipc	ra,0xfffff
    80001c2c:	eba080e7          	jalr	-326(ra) # 80000ae2 <kalloc>
    80001c30:	892a                	mv	s2,a0
    80001c32:	eca8                	sd	a0,88(s1)
    80001c34:	c535                	beqz	a0,80001ca0 <allocproc+0xc6>
  p->pagetable = proc_pagetable(p);
    80001c36:	8526                	mv	a0,s1
    80001c38:	00000097          	auipc	ra,0x0
    80001c3c:	e5c080e7          	jalr	-420(ra) # 80001a94 <proc_pagetable>
    80001c40:	892a                	mv	s2,a0
    80001c42:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c44:	c935                	beqz	a0,80001cb8 <allocproc+0xde>
  memset(&p->context, 0, sizeof(p->context));
    80001c46:	07000613          	li	a2,112
    80001c4a:	4581                	li	a1,0
    80001c4c:	06048513          	add	a0,s1,96
    80001c50:	fffff097          	auipc	ra,0xfffff
    80001c54:	07e080e7          	jalr	126(ra) # 80000cce <memset>
  p->context.ra = (uint64)forkret;
    80001c58:	00000797          	auipc	a5,0x0
    80001c5c:	db078793          	add	a5,a5,-592 # 80001a08 <forkret>
    80001c60:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c62:	60bc                	ld	a5,64(s1)
    80001c64:	6705                	lui	a4,0x1
    80001c66:	97ba                	add	a5,a5,a4
    80001c68:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001c6a:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001c6e:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001c72:	00007797          	auipc	a5,0x7
    80001c76:	c7e7a783          	lw	a5,-898(a5) # 800088f0 <ticks>
    80001c7a:	16f4a623          	sw	a5,364(s1)
    p->RTime = 0;
    80001c7e:	1604aa23          	sw	zero,372(s1)
    p->STime = 0;
    80001c82:	1604ac23          	sw	zero,376(s1)
    p->WTime = 0;
    80001c86:	1604ae23          	sw	zero,380(s1)
    p->SP = 50;
    80001c8a:	03200793          	li	a5,50
    80001c8e:	18f4a023          	sw	a5,384(s1)
}
    80001c92:	8526                	mv	a0,s1
    80001c94:	60e2                	ld	ra,24(sp)
    80001c96:	6442                	ld	s0,16(sp)
    80001c98:	64a2                	ld	s1,8(sp)
    80001c9a:	6902                	ld	s2,0(sp)
    80001c9c:	6105                	add	sp,sp,32
    80001c9e:	8082                	ret
    freeproc(p);
    80001ca0:	8526                	mv	a0,s1
    80001ca2:	00000097          	auipc	ra,0x0
    80001ca6:	ee0080e7          	jalr	-288(ra) # 80001b82 <freeproc>
    release(&p->lock);
    80001caa:	8526                	mv	a0,s1
    80001cac:	fffff097          	auipc	ra,0xfffff
    80001cb0:	fda080e7          	jalr	-38(ra) # 80000c86 <release>
    return 0;
    80001cb4:	84ca                	mv	s1,s2
    80001cb6:	bff1                	j	80001c92 <allocproc+0xb8>
    freeproc(p);
    80001cb8:	8526                	mv	a0,s1
    80001cba:	00000097          	auipc	ra,0x0
    80001cbe:	ec8080e7          	jalr	-312(ra) # 80001b82 <freeproc>
    release(&p->lock);
    80001cc2:	8526                	mv	a0,s1
    80001cc4:	fffff097          	auipc	ra,0xfffff
    80001cc8:	fc2080e7          	jalr	-62(ra) # 80000c86 <release>
    return 0;
    80001ccc:	84ca                	mv	s1,s2
    80001cce:	b7d1                	j	80001c92 <allocproc+0xb8>

0000000080001cd0 <userinit>:
{
    80001cd0:	1101                	add	sp,sp,-32
    80001cd2:	ec06                	sd	ra,24(sp)
    80001cd4:	e822                	sd	s0,16(sp)
    80001cd6:	e426                	sd	s1,8(sp)
    80001cd8:	1000                	add	s0,sp,32
  p = allocproc();
    80001cda:	00000097          	auipc	ra,0x0
    80001cde:	f00080e7          	jalr	-256(ra) # 80001bda <allocproc>
    80001ce2:	84aa                	mv	s1,a0
  initproc = p;
    80001ce4:	00007797          	auipc	a5,0x7
    80001ce8:	c0a7b223          	sd	a0,-1020(a5) # 800088e8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cec:	03400613          	li	a2,52
    80001cf0:	00007597          	auipc	a1,0x7
    80001cf4:	b9058593          	add	a1,a1,-1136 # 80008880 <initcode>
    80001cf8:	6928                	ld	a0,80(a0)
    80001cfa:	fffff097          	auipc	ra,0xfffff
    80001cfe:	640080e7          	jalr	1600(ra) # 8000133a <uvmfirst>
  p->sz = PGSIZE;
    80001d02:	6785                	lui	a5,0x1
    80001d04:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001d06:	6cb8                	ld	a4,88(s1)
    80001d08:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001d0c:	6cb8                	ld	a4,88(s1)
    80001d0e:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d10:	4641                	li	a2,16
    80001d12:	00006597          	auipc	a1,0x6
    80001d16:	4e658593          	add	a1,a1,1254 # 800081f8 <digits+0x1b8>
    80001d1a:	15848513          	add	a0,s1,344
    80001d1e:	fffff097          	auipc	ra,0xfffff
    80001d22:	0f8080e7          	jalr	248(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001d26:	00006517          	auipc	a0,0x6
    80001d2a:	4e250513          	add	a0,a0,1250 # 80008208 <digits+0x1c8>
    80001d2e:	00002097          	auipc	ra,0x2
    80001d32:	630080e7          	jalr	1584(ra) # 8000435e <namei>
    80001d36:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d3a:	478d                	li	a5,3
    80001d3c:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d3e:	8526                	mv	a0,s1
    80001d40:	fffff097          	auipc	ra,0xfffff
    80001d44:	f46080e7          	jalr	-186(ra) # 80000c86 <release>
}
    80001d48:	60e2                	ld	ra,24(sp)
    80001d4a:	6442                	ld	s0,16(sp)
    80001d4c:	64a2                	ld	s1,8(sp)
    80001d4e:	6105                	add	sp,sp,32
    80001d50:	8082                	ret

0000000080001d52 <growproc>:
{
    80001d52:	1101                	add	sp,sp,-32
    80001d54:	ec06                	sd	ra,24(sp)
    80001d56:	e822                	sd	s0,16(sp)
    80001d58:	e426                	sd	s1,8(sp)
    80001d5a:	e04a                	sd	s2,0(sp)
    80001d5c:	1000                	add	s0,sp,32
    80001d5e:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d60:	00000097          	auipc	ra,0x0
    80001d64:	c70080e7          	jalr	-912(ra) # 800019d0 <myproc>
    80001d68:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d6a:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001d6c:	01204c63          	bgtz	s2,80001d84 <growproc+0x32>
  else if (n < 0)
    80001d70:	02094663          	bltz	s2,80001d9c <growproc+0x4a>
  p->sz = sz;
    80001d74:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d76:	4501                	li	a0,0
}
    80001d78:	60e2                	ld	ra,24(sp)
    80001d7a:	6442                	ld	s0,16(sp)
    80001d7c:	64a2                	ld	s1,8(sp)
    80001d7e:	6902                	ld	s2,0(sp)
    80001d80:	6105                	add	sp,sp,32
    80001d82:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d84:	4691                	li	a3,4
    80001d86:	00b90633          	add	a2,s2,a1
    80001d8a:	6928                	ld	a0,80(a0)
    80001d8c:	fffff097          	auipc	ra,0xfffff
    80001d90:	668080e7          	jalr	1640(ra) # 800013f4 <uvmalloc>
    80001d94:	85aa                	mv	a1,a0
    80001d96:	fd79                	bnez	a0,80001d74 <growproc+0x22>
      return -1;
    80001d98:	557d                	li	a0,-1
    80001d9a:	bff9                	j	80001d78 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d9c:	00b90633          	add	a2,s2,a1
    80001da0:	6928                	ld	a0,80(a0)
    80001da2:	fffff097          	auipc	ra,0xfffff
    80001da6:	60a080e7          	jalr	1546(ra) # 800013ac <uvmdealloc>
    80001daa:	85aa                	mv	a1,a0
    80001dac:	b7e1                	j	80001d74 <growproc+0x22>

0000000080001dae <fork>:
{
    80001dae:	7139                	add	sp,sp,-64
    80001db0:	fc06                	sd	ra,56(sp)
    80001db2:	f822                	sd	s0,48(sp)
    80001db4:	f426                	sd	s1,40(sp)
    80001db6:	f04a                	sd	s2,32(sp)
    80001db8:	ec4e                	sd	s3,24(sp)
    80001dba:	e852                	sd	s4,16(sp)
    80001dbc:	e456                	sd	s5,8(sp)
    80001dbe:	0080                	add	s0,sp,64
  struct proc *p = myproc();
    80001dc0:	00000097          	auipc	ra,0x0
    80001dc4:	c10080e7          	jalr	-1008(ra) # 800019d0 <myproc>
    80001dc8:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001dca:	00000097          	auipc	ra,0x0
    80001dce:	e10080e7          	jalr	-496(ra) # 80001bda <allocproc>
    80001dd2:	10050c63          	beqz	a0,80001eea <fork+0x13c>
    80001dd6:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001dd8:	048ab603          	ld	a2,72(s5)
    80001ddc:	692c                	ld	a1,80(a0)
    80001dde:	050ab503          	ld	a0,80(s5)
    80001de2:	fffff097          	auipc	ra,0xfffff
    80001de6:	76a080e7          	jalr	1898(ra) # 8000154c <uvmcopy>
    80001dea:	04054863          	bltz	a0,80001e3a <fork+0x8c>
  np->sz = p->sz;
    80001dee:	048ab783          	ld	a5,72(s5)
    80001df2:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001df6:	058ab683          	ld	a3,88(s5)
    80001dfa:	87b6                	mv	a5,a3
    80001dfc:	058a3703          	ld	a4,88(s4)
    80001e00:	12068693          	add	a3,a3,288
    80001e04:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e08:	6788                	ld	a0,8(a5)
    80001e0a:	6b8c                	ld	a1,16(a5)
    80001e0c:	6f90                	ld	a2,24(a5)
    80001e0e:	01073023          	sd	a6,0(a4)
    80001e12:	e708                	sd	a0,8(a4)
    80001e14:	eb0c                	sd	a1,16(a4)
    80001e16:	ef10                	sd	a2,24(a4)
    80001e18:	02078793          	add	a5,a5,32
    80001e1c:	02070713          	add	a4,a4,32
    80001e20:	fed792e3          	bne	a5,a3,80001e04 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e24:	058a3783          	ld	a5,88(s4)
    80001e28:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001e2c:	0d0a8493          	add	s1,s5,208
    80001e30:	0d0a0913          	add	s2,s4,208
    80001e34:	150a8993          	add	s3,s5,336
    80001e38:	a00d                	j	80001e5a <fork+0xac>
    freeproc(np);
    80001e3a:	8552                	mv	a0,s4
    80001e3c:	00000097          	auipc	ra,0x0
    80001e40:	d46080e7          	jalr	-698(ra) # 80001b82 <freeproc>
    release(&np->lock);
    80001e44:	8552                	mv	a0,s4
    80001e46:	fffff097          	auipc	ra,0xfffff
    80001e4a:	e40080e7          	jalr	-448(ra) # 80000c86 <release>
    return -1;
    80001e4e:	597d                	li	s2,-1
    80001e50:	a059                	j	80001ed6 <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001e52:	04a1                	add	s1,s1,8
    80001e54:	0921                	add	s2,s2,8
    80001e56:	01348b63          	beq	s1,s3,80001e6c <fork+0xbe>
    if (p->ofile[i])
    80001e5a:	6088                	ld	a0,0(s1)
    80001e5c:	d97d                	beqz	a0,80001e52 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e5e:	00003097          	auipc	ra,0x3
    80001e62:	b72080e7          	jalr	-1166(ra) # 800049d0 <filedup>
    80001e66:	00a93023          	sd	a0,0(s2)
    80001e6a:	b7e5                	j	80001e52 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e6c:	150ab503          	ld	a0,336(s5)
    80001e70:	00002097          	auipc	ra,0x2
    80001e74:	d0a080e7          	jalr	-758(ra) # 80003b7a <idup>
    80001e78:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e7c:	4641                	li	a2,16
    80001e7e:	158a8593          	add	a1,s5,344
    80001e82:	158a0513          	add	a0,s4,344
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	f90080e7          	jalr	-112(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80001e8e:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e92:	8552                	mv	a0,s4
    80001e94:	fffff097          	auipc	ra,0xfffff
    80001e98:	df2080e7          	jalr	-526(ra) # 80000c86 <release>
  acquire(&wait_lock);
    80001e9c:	0000f497          	auipc	s1,0xf
    80001ea0:	cdc48493          	add	s1,s1,-804 # 80010b78 <wait_lock>
    80001ea4:	8526                	mv	a0,s1
    80001ea6:	fffff097          	auipc	ra,0xfffff
    80001eaa:	d2c080e7          	jalr	-724(ra) # 80000bd2 <acquire>
  np->parent = p;
    80001eae:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001eb2:	8526                	mv	a0,s1
    80001eb4:	fffff097          	auipc	ra,0xfffff
    80001eb8:	dd2080e7          	jalr	-558(ra) # 80000c86 <release>
  acquire(&np->lock);
    80001ebc:	8552                	mv	a0,s4
    80001ebe:	fffff097          	auipc	ra,0xfffff
    80001ec2:	d14080e7          	jalr	-748(ra) # 80000bd2 <acquire>
  np->state = RUNNABLE;
    80001ec6:	478d                	li	a5,3
    80001ec8:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ecc:	8552                	mv	a0,s4
    80001ece:	fffff097          	auipc	ra,0xfffff
    80001ed2:	db8080e7          	jalr	-584(ra) # 80000c86 <release>
}
    80001ed6:	854a                	mv	a0,s2
    80001ed8:	70e2                	ld	ra,56(sp)
    80001eda:	7442                	ld	s0,48(sp)
    80001edc:	74a2                	ld	s1,40(sp)
    80001ede:	7902                	ld	s2,32(sp)
    80001ee0:	69e2                	ld	s3,24(sp)
    80001ee2:	6a42                	ld	s4,16(sp)
    80001ee4:	6aa2                	ld	s5,8(sp)
    80001ee6:	6121                	add	sp,sp,64
    80001ee8:	8082                	ret
    return -1;
    80001eea:	597d                	li	s2,-1
    80001eec:	b7ed                	j	80001ed6 <fork+0x128>

0000000080001eee <GetRBI>:
  int GetRBI(uint RTime, uint STime, uint WTime){
    80001eee:	1141                	add	sp,sp,-16
    80001ef0:	e422                	sd	s0,8(sp)
    80001ef2:	0800                	add	s0,sp,16
    int a = 3*RTime - STime - WTime;
    80001ef4:	0015171b          	sllw	a4,a0,0x1
    80001ef8:	9f29                	addw	a4,a4,a0
    80001efa:	00c587bb          	addw	a5,a1,a2
    80001efe:	9f1d                	subw	a4,a4,a5
    a *= 50;
    80001f00:	03200793          	li	a5,50
    80001f04:	02e787bb          	mulw	a5,a5,a4
    a /= RTime + STime + WTime + 1;
    80001f08:	2605                	addw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80001f0a:	9db1                	addw	a1,a1,a2
    80001f0c:	9d2d                	addw	a0,a0,a1
    80001f0e:	02a7d53b          	divuw	a0,a5,a0
    if (a<0) return 0;
    80001f12:	0005079b          	sext.w	a5,a0
    80001f16:	fff7c793          	not	a5,a5
    80001f1a:	97fd                	sra	a5,a5,0x3f
    80001f1c:	8d7d                	and	a0,a0,a5
  }
    80001f1e:	2501                	sext.w	a0,a0
    80001f20:	6422                	ld	s0,8(sp)
    80001f22:	0141                	add	sp,sp,16
    80001f24:	8082                	ret

0000000080001f26 <UpdateTimes>:
  void UpdateTimes(int sel_p_idx){
    80001f26:	715d                	add	sp,sp,-80
    80001f28:	e486                	sd	ra,72(sp)
    80001f2a:	e0a2                	sd	s0,64(sp)
    80001f2c:	fc26                	sd	s1,56(sp)
    80001f2e:	f84a                	sd	s2,48(sp)
    80001f30:	f44e                	sd	s3,40(sp)
    80001f32:	f052                	sd	s4,32(sp)
    80001f34:	ec56                	sd	s5,24(sp)
    80001f36:	e85a                	sd	s6,16(sp)
    80001f38:	e45e                	sd	s7,8(sp)
    80001f3a:	0880                	add	s0,sp,80
    80001f3c:	8a2a                	mv	s4,a0
    for (int p_idx = 0; p_idx < NPROC; p_idx++)
    80001f3e:	0000f497          	auipc	s1,0xf
    80001f42:	05248493          	add	s1,s1,82 # 80010f90 <proc>
    80001f46:	4901                	li	s2,0
        if (proc[p_idx].state == SLEEPING)
    80001f48:	4b09                	li	s6,2
        if (proc[p_idx].state == RUNNABLE)
    80001f4a:	4b8d                	li	s7,3
    for (int p_idx = 0; p_idx < NPROC; p_idx++)
    80001f4c:	04000a93          	li	s5,64
    80001f50:	a805                	j	80001f80 <UpdateTimes+0x5a>
        proc[p_idx].RTime ++;
    80001f52:	1744a783          	lw	a5,372(s1)
    80001f56:	2785                	addw	a5,a5,1
    80001f58:	16f4aa23          	sw	a5,372(s1)
        proc[p_idx].STime = 0;
    80001f5c:	1604ac23          	sw	zero,376(s1)
    80001f60:	a031                	j	80001f6c <UpdateTimes+0x46>
          proc[p_idx].STime ++;
    80001f62:	1784a783          	lw	a5,376(s1)
    80001f66:	2785                	addw	a5,a5,1
    80001f68:	16f4ac23          	sw	a5,376(s1)
      release (&proc[p_idx].lock);
    80001f6c:	854e                	mv	a0,s3
    80001f6e:	fffff097          	auipc	ra,0xfffff
    80001f72:	d18080e7          	jalr	-744(ra) # 80000c86 <release>
    for (int p_idx = 0; p_idx < NPROC; p_idx++)
    80001f76:	2905                	addw	s2,s2,1
    80001f78:	18848493          	add	s1,s1,392
    80001f7c:	03590763          	beq	s2,s5,80001faa <UpdateTimes+0x84>
      acquire (&proc[p_idx].lock);
    80001f80:	89a6                	mv	s3,s1
    80001f82:	8526                	mv	a0,s1
    80001f84:	fffff097          	auipc	ra,0xfffff
    80001f88:	c4e080e7          	jalr	-946(ra) # 80000bd2 <acquire>
      if (p_idx == sel_p_idx){
    80001f8c:	fd2a03e3          	beq	s4,s2,80001f52 <UpdateTimes+0x2c>
        proc[p_idx].RTime = 0;
    80001f90:	1604aa23          	sw	zero,372(s1)
        if (proc[p_idx].state == SLEEPING)
    80001f94:	4c9c                	lw	a5,24(s1)
    80001f96:	fd6786e3          	beq	a5,s6,80001f62 <UpdateTimes+0x3c>
        if (proc[p_idx].state == RUNNABLE)
    80001f9a:	fd7799e3          	bne	a5,s7,80001f6c <UpdateTimes+0x46>
          proc[p_idx].WTime ++;
    80001f9e:	17c4a783          	lw	a5,380(s1)
    80001fa2:	2785                	addw	a5,a5,1
    80001fa4:	16f4ae23          	sw	a5,380(s1)
    80001fa8:	b7d1                	j	80001f6c <UpdateTimes+0x46>
  }
    80001faa:	60a6                	ld	ra,72(sp)
    80001fac:	6406                	ld	s0,64(sp)
    80001fae:	74e2                	ld	s1,56(sp)
    80001fb0:	7942                	ld	s2,48(sp)
    80001fb2:	79a2                	ld	s3,40(sp)
    80001fb4:	7a02                	ld	s4,32(sp)
    80001fb6:	6ae2                	ld	s5,24(sp)
    80001fb8:	6b42                	ld	s6,16(sp)
    80001fba:	6ba2                	ld	s7,8(sp)
    80001fbc:	6161                	add	sp,sp,80
    80001fbe:	8082                	ret

0000000080001fc0 <scheduler>:
{
    80001fc0:	7175                	add	sp,sp,-144
    80001fc2:	e506                	sd	ra,136(sp)
    80001fc4:	e122                	sd	s0,128(sp)
    80001fc6:	fca6                	sd	s1,120(sp)
    80001fc8:	f8ca                	sd	s2,112(sp)
    80001fca:	f4ce                	sd	s3,104(sp)
    80001fcc:	f0d2                	sd	s4,96(sp)
    80001fce:	ecd6                	sd	s5,88(sp)
    80001fd0:	e8da                	sd	s6,80(sp)
    80001fd2:	e4de                	sd	s7,72(sp)
    80001fd4:	e0e2                	sd	s8,64(sp)
    80001fd6:	fc66                	sd	s9,56(sp)
    80001fd8:	f86a                	sd	s10,48(sp)
    80001fda:	f46e                	sd	s11,40(sp)
    80001fdc:	0900                	add	s0,sp,144
    80001fde:	8792                	mv	a5,tp
  int id = r_tp();
    80001fe0:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fe2:	00779693          	sll	a3,a5,0x7
    80001fe6:	0000f717          	auipc	a4,0xf
    80001fea:	b7a70713          	add	a4,a4,-1158 # 80010b60 <pid_lock>
    80001fee:	9736                	add	a4,a4,a3
    80001ff0:	02073823          	sd	zero,48(a4)
      swtch(&c->context, &p->context);
    80001ff4:	0000f717          	auipc	a4,0xf
    80001ff8:	ba470713          	add	a4,a4,-1116 # 80010b98 <cpus+0x8>
    80001ffc:	9736                	add	a4,a4,a3
    80001ffe:	f8e43023          	sd	a4,-128(s0)
      int min_dp = 100001;
    80002002:	6761                	lui	a4,0x18
    80002004:	6a170713          	add	a4,a4,1697 # 186a1 <_entry-0x7ffe795f>
    80002008:	f8e43423          	sd	a4,-120(s0)
      for (int p_idx = 0; p_idx < NPROC; p_idx++)
    8000200c:	04000a93          	li	s5,64
          if (dp < min_dp || (dp == min_dp && proc[p_idx].ctime <  proc[max_p_idx].ctime) ){
    80002010:	0000fd17          	auipc	s10,0xf
    80002014:	f80d0d13          	add	s10,s10,-128 # 80010f90 <proc>
      c->proc = p;
    80002018:	0000f717          	auipc	a4,0xf
    8000201c:	b4870713          	add	a4,a4,-1208 # 80010b60 <pid_lock>
    80002020:	00d707b3          	add	a5,a4,a3
    80002024:	f6f43c23          	sd	a5,-136(s0)
    80002028:	a239                	j	80002136 <scheduler+0x176>
        release(&proc[p_idx].lock);
    8000202a:	854e                	mv	a0,s3
    8000202c:	fffff097          	auipc	ra,0xfffff
    80002030:	c5a080e7          	jalr	-934(ra) # 80000c86 <release>
      for (int p_idx = 0; p_idx < NPROC; p_idx++)
    80002034:	2905                	addw	s2,s2,1
    80002036:	18848493          	add	s1,s1,392
    8000203a:	07590263          	beq	s2,s5,8000209e <scheduler+0xde>
        acquire(&proc[p_idx].lock);
    8000203e:	89a6                	mv	s3,s1
    80002040:	8526                	mv	a0,s1
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	b90080e7          	jalr	-1136(ra) # 80000bd2 <acquire>
        if (proc[p_idx].state == RUNNABLE)
    8000204a:	4c9c                	lw	a5,24(s1)
    8000204c:	fd479fe3          	bne	a5,s4,8000202a <scheduler+0x6a>
          int rbi  = GetRBI(p->RTime, p->STime, p->WTime);
    80002050:	17c4a603          	lw	a2,380(s1)
    80002054:	1784a583          	lw	a1,376(s1)
    80002058:	1744a503          	lw	a0,372(s1)
    8000205c:	00000097          	auipc	ra,0x0
    80002060:	e92080e7          	jalr	-366(ra) # 80001eee <GetRBI>
          int dp = p->SP+ rbi;
    80002064:	1804a783          	lw	a5,384(s1)
    80002068:	9d3d                	addw	a0,a0,a5
          if (dp < 0) dp = 0;
    8000206a:	0005079b          	sext.w	a5,a0
    8000206e:	fff7c793          	not	a5,a5
    80002072:	97fd                	sra	a5,a5,0x3f
    80002074:	8d7d                	and	a0,a0,a5
    80002076:	0005079b          	sext.w	a5,a0
    8000207a:	00fbd363          	bge	s7,a5,80002080 <scheduler+0xc0>
    8000207e:	8566                	mv	a0,s9
    80002080:	2501                	sext.w	a0,a0
          if (dp < min_dp || (dp == min_dp && proc[p_idx].ctime <  proc[max_p_idx].ctime) ){
    80002082:	05654363          	blt	a0,s6,800020c8 <scheduler+0x108>
    80002086:	fb6512e3          	bne	a0,s6,8000202a <scheduler+0x6a>
    8000208a:	03bc07b3          	mul	a5,s8,s11
    8000208e:	97ea                	add	a5,a5,s10
    80002090:	16c9a703          	lw	a4,364(s3)
    80002094:	16c7a783          	lw	a5,364(a5)
    80002098:	02f76963          	bltu	a4,a5,800020ca <scheduler+0x10a>
    8000209c:	b779                	j	8000202a <scheduler+0x6a>
      if (max_p_idx == -1){
    8000209e:	57fd                	li	a5,-1
    800020a0:	04fc1463          	bne	s8,a5,800020e8 <scheduler+0x128>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020a4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020a8:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020ac:	10079073          	csrw	sstatus,a5
      for (int p_idx = 0; p_idx < NPROC; p_idx++)
    800020b0:	0000f497          	auipc	s1,0xf
    800020b4:	ee048493          	add	s1,s1,-288 # 80010f90 <proc>
    800020b8:	4901                	li	s2,0
      int min_dp = 100001;
    800020ba:	f8843b03          	ld	s6,-120(s0)
      int max_p_idx = -1;
    800020be:	5c7d                	li	s8,-1
        if (proc[p_idx].state == RUNNABLE)
    800020c0:	4a0d                	li	s4,3
          if (dp < min_dp || (dp == min_dp && proc[p_idx].ctime <  proc[max_p_idx].ctime) ){
    800020c2:	18800d93          	li	s11,392
    800020c6:	bfa5                	j	8000203e <scheduler+0x7e>
            min_dp = dp;
    800020c8:	8b2a                	mv	s6,a0
        release(&proc[p_idx].lock);
    800020ca:	854e                	mv	a0,s3
    800020cc:	fffff097          	auipc	ra,0xfffff
    800020d0:	bba080e7          	jalr	-1094(ra) # 80000c86 <release>
      for (int p_idx = 0; p_idx < NPROC; p_idx++)
    800020d4:	0019079b          	addw	a5,s2,1
    800020d8:	18848493          	add	s1,s1,392
    800020dc:	01578563          	beq	a5,s5,800020e6 <scheduler+0x126>
    800020e0:	8c4a                	mv	s8,s2
    800020e2:	893e                	mv	s2,a5
    800020e4:	bfa9                	j	8000203e <scheduler+0x7e>
    800020e6:	8c4a                	mv	s8,s2
      UpdateTimes(max_p_idx);
    800020e8:	8562                	mv	a0,s8
    800020ea:	00000097          	auipc	ra,0x0
    800020ee:	e3c080e7          	jalr	-452(ra) # 80001f26 <UpdateTimes>
      p = &proc[max_p_idx];
    800020f2:	18800493          	li	s1,392
    800020f6:	029c04b3          	mul	s1,s8,s1
    800020fa:	01a48933          	add	s2,s1,s10
      acquire(&p->lock);
    800020fe:	854a                	mv	a0,s2
    80002100:	fffff097          	auipc	ra,0xfffff
    80002104:	ad2080e7          	jalr	-1326(ra) # 80000bd2 <acquire>
      p->state = RUNNING;
    80002108:	4791                	li	a5,4
    8000210a:	00f92c23          	sw	a5,24(s2)
      c->proc = p;
    8000210e:	f7843983          	ld	s3,-136(s0)
    80002112:	0329b823          	sd	s2,48(s3)
      swtch(&c->context, &p->context);
    80002116:	06048593          	add	a1,s1,96
    8000211a:	95ea                	add	a1,a1,s10
    8000211c:	f8043503          	ld	a0,-128(s0)
    80002120:	00001097          	auipc	ra,0x1
    80002124:	84c080e7          	jalr	-1972(ra) # 8000296c <swtch>
      c->proc = 0;
    80002128:	0209b823          	sd	zero,48(s3)
      release(&p->lock);
    8000212c:	854a                	mv	a0,s2
    8000212e:	fffff097          	auipc	ra,0xfffff
    80002132:	b58080e7          	jalr	-1192(ra) # 80000c86 <release>
    80002136:	06400b93          	li	s7,100
    8000213a:	06400c93          	li	s9,100
    8000213e:	b79d                	j	800020a4 <scheduler+0xe4>

0000000080002140 <sched>:
{
    80002140:	7179                	add	sp,sp,-48
    80002142:	f406                	sd	ra,40(sp)
    80002144:	f022                	sd	s0,32(sp)
    80002146:	ec26                	sd	s1,24(sp)
    80002148:	e84a                	sd	s2,16(sp)
    8000214a:	e44e                	sd	s3,8(sp)
    8000214c:	1800                	add	s0,sp,48
  struct proc *p = myproc();
    8000214e:	00000097          	auipc	ra,0x0
    80002152:	882080e7          	jalr	-1918(ra) # 800019d0 <myproc>
    80002156:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80002158:	fffff097          	auipc	ra,0xfffff
    8000215c:	a00080e7          	jalr	-1536(ra) # 80000b58 <holding>
    80002160:	c93d                	beqz	a0,800021d6 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002162:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002164:	2781                	sext.w	a5,a5
    80002166:	079e                	sll	a5,a5,0x7
    80002168:	0000f717          	auipc	a4,0xf
    8000216c:	9f870713          	add	a4,a4,-1544 # 80010b60 <pid_lock>
    80002170:	97ba                	add	a5,a5,a4
    80002172:	0a87a703          	lw	a4,168(a5)
    80002176:	4785                	li	a5,1
    80002178:	06f71763          	bne	a4,a5,800021e6 <sched+0xa6>
  if (p->state == RUNNING)
    8000217c:	4c98                	lw	a4,24(s1)
    8000217e:	4791                	li	a5,4
    80002180:	06f70b63          	beq	a4,a5,800021f6 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002184:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002188:	8b89                	and	a5,a5,2
  if (intr_get())
    8000218a:	efb5                	bnez	a5,80002206 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000218c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000218e:	0000f917          	auipc	s2,0xf
    80002192:	9d290913          	add	s2,s2,-1582 # 80010b60 <pid_lock>
    80002196:	2781                	sext.w	a5,a5
    80002198:	079e                	sll	a5,a5,0x7
    8000219a:	97ca                	add	a5,a5,s2
    8000219c:	0ac7a983          	lw	s3,172(a5)
    800021a0:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800021a2:	2781                	sext.w	a5,a5
    800021a4:	079e                	sll	a5,a5,0x7
    800021a6:	0000f597          	auipc	a1,0xf
    800021aa:	9f258593          	add	a1,a1,-1550 # 80010b98 <cpus+0x8>
    800021ae:	95be                	add	a1,a1,a5
    800021b0:	06048513          	add	a0,s1,96
    800021b4:	00000097          	auipc	ra,0x0
    800021b8:	7b8080e7          	jalr	1976(ra) # 8000296c <swtch>
    800021bc:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800021be:	2781                	sext.w	a5,a5
    800021c0:	079e                	sll	a5,a5,0x7
    800021c2:	993e                	add	s2,s2,a5
    800021c4:	0b392623          	sw	s3,172(s2)
}
    800021c8:	70a2                	ld	ra,40(sp)
    800021ca:	7402                	ld	s0,32(sp)
    800021cc:	64e2                	ld	s1,24(sp)
    800021ce:	6942                	ld	s2,16(sp)
    800021d0:	69a2                	ld	s3,8(sp)
    800021d2:	6145                	add	sp,sp,48
    800021d4:	8082                	ret
    panic("sched p->lock");
    800021d6:	00006517          	auipc	a0,0x6
    800021da:	03a50513          	add	a0,a0,58 # 80008210 <digits+0x1d0>
    800021de:	ffffe097          	auipc	ra,0xffffe
    800021e2:	35e080e7          	jalr	862(ra) # 8000053c <panic>
    panic("sched locks");
    800021e6:	00006517          	auipc	a0,0x6
    800021ea:	03a50513          	add	a0,a0,58 # 80008220 <digits+0x1e0>
    800021ee:	ffffe097          	auipc	ra,0xffffe
    800021f2:	34e080e7          	jalr	846(ra) # 8000053c <panic>
    panic("sched running");
    800021f6:	00006517          	auipc	a0,0x6
    800021fa:	03a50513          	add	a0,a0,58 # 80008230 <digits+0x1f0>
    800021fe:	ffffe097          	auipc	ra,0xffffe
    80002202:	33e080e7          	jalr	830(ra) # 8000053c <panic>
    panic("sched interruptible");
    80002206:	00006517          	auipc	a0,0x6
    8000220a:	03a50513          	add	a0,a0,58 # 80008240 <digits+0x200>
    8000220e:	ffffe097          	auipc	ra,0xffffe
    80002212:	32e080e7          	jalr	814(ra) # 8000053c <panic>

0000000080002216 <yield>:
{
    80002216:	1101                	add	sp,sp,-32
    80002218:	ec06                	sd	ra,24(sp)
    8000221a:	e822                	sd	s0,16(sp)
    8000221c:	e426                	sd	s1,8(sp)
    8000221e:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    80002220:	fffff097          	auipc	ra,0xfffff
    80002224:	7b0080e7          	jalr	1968(ra) # 800019d0 <myproc>
    80002228:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	9a8080e7          	jalr	-1624(ra) # 80000bd2 <acquire>
  p->state = RUNNABLE;
    80002232:	478d                	li	a5,3
    80002234:	cc9c                	sw	a5,24(s1)
  sched();
    80002236:	00000097          	auipc	ra,0x0
    8000223a:	f0a080e7          	jalr	-246(ra) # 80002140 <sched>
  release(&p->lock);
    8000223e:	8526                	mv	a0,s1
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	a46080e7          	jalr	-1466(ra) # 80000c86 <release>
}
    80002248:	60e2                	ld	ra,24(sp)
    8000224a:	6442                	ld	s0,16(sp)
    8000224c:	64a2                	ld	s1,8(sp)
    8000224e:	6105                	add	sp,sp,32
    80002250:	8082                	ret

0000000080002252 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002252:	7179                	add	sp,sp,-48
    80002254:	f406                	sd	ra,40(sp)
    80002256:	f022                	sd	s0,32(sp)
    80002258:	ec26                	sd	s1,24(sp)
    8000225a:	e84a                	sd	s2,16(sp)
    8000225c:	e44e                	sd	s3,8(sp)
    8000225e:	1800                	add	s0,sp,48
    80002260:	89aa                	mv	s3,a0
    80002262:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002264:	fffff097          	auipc	ra,0xfffff
    80002268:	76c080e7          	jalr	1900(ra) # 800019d0 <myproc>
    8000226c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    8000226e:	fffff097          	auipc	ra,0xfffff
    80002272:	964080e7          	jalr	-1692(ra) # 80000bd2 <acquire>
  release(lk);
    80002276:	854a                	mv	a0,s2
    80002278:	fffff097          	auipc	ra,0xfffff
    8000227c:	a0e080e7          	jalr	-1522(ra) # 80000c86 <release>

  // Go to sleep.
  p->chan = chan;
    80002280:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002284:	4789                	li	a5,2
    80002286:	cc9c                	sw	a5,24(s1)

  sched();
    80002288:	00000097          	auipc	ra,0x0
    8000228c:	eb8080e7          	jalr	-328(ra) # 80002140 <sched>

  // Tidy up.
  p->chan = 0;
    80002290:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002294:	8526                	mv	a0,s1
    80002296:	fffff097          	auipc	ra,0xfffff
    8000229a:	9f0080e7          	jalr	-1552(ra) # 80000c86 <release>
  acquire(lk);
    8000229e:	854a                	mv	a0,s2
    800022a0:	fffff097          	auipc	ra,0xfffff
    800022a4:	932080e7          	jalr	-1742(ra) # 80000bd2 <acquire>
}
    800022a8:	70a2                	ld	ra,40(sp)
    800022aa:	7402                	ld	s0,32(sp)
    800022ac:	64e2                	ld	s1,24(sp)
    800022ae:	6942                	ld	s2,16(sp)
    800022b0:	69a2                	ld	s3,8(sp)
    800022b2:	6145                	add	sp,sp,48
    800022b4:	8082                	ret

00000000800022b6 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800022b6:	7139                	add	sp,sp,-64
    800022b8:	fc06                	sd	ra,56(sp)
    800022ba:	f822                	sd	s0,48(sp)
    800022bc:	f426                	sd	s1,40(sp)
    800022be:	f04a                	sd	s2,32(sp)
    800022c0:	ec4e                	sd	s3,24(sp)
    800022c2:	e852                	sd	s4,16(sp)
    800022c4:	e456                	sd	s5,8(sp)
    800022c6:	0080                	add	s0,sp,64
    800022c8:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800022ca:	0000f497          	auipc	s1,0xf
    800022ce:	cc648493          	add	s1,s1,-826 # 80010f90 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800022d2:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    800022d4:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    800022d6:	00015917          	auipc	s2,0x15
    800022da:	eba90913          	add	s2,s2,-326 # 80017190 <tickslock>
    800022de:	a811                	j	800022f2 <wakeup+0x3c>
      }
      release(&p->lock);
    800022e0:	8526                	mv	a0,s1
    800022e2:	fffff097          	auipc	ra,0xfffff
    800022e6:	9a4080e7          	jalr	-1628(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800022ea:	18848493          	add	s1,s1,392
    800022ee:	03248663          	beq	s1,s2,8000231a <wakeup+0x64>
    if (p != myproc())
    800022f2:	fffff097          	auipc	ra,0xfffff
    800022f6:	6de080e7          	jalr	1758(ra) # 800019d0 <myproc>
    800022fa:	fea488e3          	beq	s1,a0,800022ea <wakeup+0x34>
      acquire(&p->lock);
    800022fe:	8526                	mv	a0,s1
    80002300:	fffff097          	auipc	ra,0xfffff
    80002304:	8d2080e7          	jalr	-1838(ra) # 80000bd2 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002308:	4c9c                	lw	a5,24(s1)
    8000230a:	fd379be3          	bne	a5,s3,800022e0 <wakeup+0x2a>
    8000230e:	709c                	ld	a5,32(s1)
    80002310:	fd4798e3          	bne	a5,s4,800022e0 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002314:	0154ac23          	sw	s5,24(s1)
    80002318:	b7e1                	j	800022e0 <wakeup+0x2a>
    }
  }
}
    8000231a:	70e2                	ld	ra,56(sp)
    8000231c:	7442                	ld	s0,48(sp)
    8000231e:	74a2                	ld	s1,40(sp)
    80002320:	7902                	ld	s2,32(sp)
    80002322:	69e2                	ld	s3,24(sp)
    80002324:	6a42                	ld	s4,16(sp)
    80002326:	6aa2                	ld	s5,8(sp)
    80002328:	6121                	add	sp,sp,64
    8000232a:	8082                	ret

000000008000232c <reparent>:
{
    8000232c:	7179                	add	sp,sp,-48
    8000232e:	f406                	sd	ra,40(sp)
    80002330:	f022                	sd	s0,32(sp)
    80002332:	ec26                	sd	s1,24(sp)
    80002334:	e84a                	sd	s2,16(sp)
    80002336:	e44e                	sd	s3,8(sp)
    80002338:	e052                	sd	s4,0(sp)
    8000233a:	1800                	add	s0,sp,48
    8000233c:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000233e:	0000f497          	auipc	s1,0xf
    80002342:	c5248493          	add	s1,s1,-942 # 80010f90 <proc>
      pp->parent = initproc;
    80002346:	00006a17          	auipc	s4,0x6
    8000234a:	5a2a0a13          	add	s4,s4,1442 # 800088e8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000234e:	00015997          	auipc	s3,0x15
    80002352:	e4298993          	add	s3,s3,-446 # 80017190 <tickslock>
    80002356:	a029                	j	80002360 <reparent+0x34>
    80002358:	18848493          	add	s1,s1,392
    8000235c:	01348d63          	beq	s1,s3,80002376 <reparent+0x4a>
    if (pp->parent == p)
    80002360:	7c9c                	ld	a5,56(s1)
    80002362:	ff279be3          	bne	a5,s2,80002358 <reparent+0x2c>
      pp->parent = initproc;
    80002366:	000a3503          	ld	a0,0(s4)
    8000236a:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000236c:	00000097          	auipc	ra,0x0
    80002370:	f4a080e7          	jalr	-182(ra) # 800022b6 <wakeup>
    80002374:	b7d5                	j	80002358 <reparent+0x2c>
}
    80002376:	70a2                	ld	ra,40(sp)
    80002378:	7402                	ld	s0,32(sp)
    8000237a:	64e2                	ld	s1,24(sp)
    8000237c:	6942                	ld	s2,16(sp)
    8000237e:	69a2                	ld	s3,8(sp)
    80002380:	6a02                	ld	s4,0(sp)
    80002382:	6145                	add	sp,sp,48
    80002384:	8082                	ret

0000000080002386 <exit>:
{
    80002386:	7179                	add	sp,sp,-48
    80002388:	f406                	sd	ra,40(sp)
    8000238a:	f022                	sd	s0,32(sp)
    8000238c:	ec26                	sd	s1,24(sp)
    8000238e:	e84a                	sd	s2,16(sp)
    80002390:	e44e                	sd	s3,8(sp)
    80002392:	e052                	sd	s4,0(sp)
    80002394:	1800                	add	s0,sp,48
    80002396:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	638080e7          	jalr	1592(ra) # 800019d0 <myproc>
    800023a0:	89aa                	mv	s3,a0
  if (p == initproc)
    800023a2:	00006797          	auipc	a5,0x6
    800023a6:	5467b783          	ld	a5,1350(a5) # 800088e8 <initproc>
    800023aa:	0d050493          	add	s1,a0,208
    800023ae:	15050913          	add	s2,a0,336
    800023b2:	02a79363          	bne	a5,a0,800023d8 <exit+0x52>
    panic("init exiting");
    800023b6:	00006517          	auipc	a0,0x6
    800023ba:	ea250513          	add	a0,a0,-350 # 80008258 <digits+0x218>
    800023be:	ffffe097          	auipc	ra,0xffffe
    800023c2:	17e080e7          	jalr	382(ra) # 8000053c <panic>
      fileclose(f);
    800023c6:	00002097          	auipc	ra,0x2
    800023ca:	65c080e7          	jalr	1628(ra) # 80004a22 <fileclose>
      p->ofile[fd] = 0;
    800023ce:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800023d2:	04a1                	add	s1,s1,8
    800023d4:	01248563          	beq	s1,s2,800023de <exit+0x58>
    if (p->ofile[fd])
    800023d8:	6088                	ld	a0,0(s1)
    800023da:	f575                	bnez	a0,800023c6 <exit+0x40>
    800023dc:	bfdd                	j	800023d2 <exit+0x4c>
  begin_op();
    800023de:	00002097          	auipc	ra,0x2
    800023e2:	180080e7          	jalr	384(ra) # 8000455e <begin_op>
  iput(p->cwd);
    800023e6:	1509b503          	ld	a0,336(s3)
    800023ea:	00002097          	auipc	ra,0x2
    800023ee:	988080e7          	jalr	-1656(ra) # 80003d72 <iput>
  end_op();
    800023f2:	00002097          	auipc	ra,0x2
    800023f6:	1e6080e7          	jalr	486(ra) # 800045d8 <end_op>
  p->cwd = 0;
    800023fa:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800023fe:	0000e497          	auipc	s1,0xe
    80002402:	77a48493          	add	s1,s1,1914 # 80010b78 <wait_lock>
    80002406:	8526                	mv	a0,s1
    80002408:	ffffe097          	auipc	ra,0xffffe
    8000240c:	7ca080e7          	jalr	1994(ra) # 80000bd2 <acquire>
  reparent(p);
    80002410:	854e                	mv	a0,s3
    80002412:	00000097          	auipc	ra,0x0
    80002416:	f1a080e7          	jalr	-230(ra) # 8000232c <reparent>
  wakeup(p->parent);
    8000241a:	0389b503          	ld	a0,56(s3)
    8000241e:	00000097          	auipc	ra,0x0
    80002422:	e98080e7          	jalr	-360(ra) # 800022b6 <wakeup>
  acquire(&p->lock);
    80002426:	854e                	mv	a0,s3
    80002428:	ffffe097          	auipc	ra,0xffffe
    8000242c:	7aa080e7          	jalr	1962(ra) # 80000bd2 <acquire>
  p->xstate = status;
    80002430:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002434:	4795                	li	a5,5
    80002436:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    8000243a:	00006797          	auipc	a5,0x6
    8000243e:	4b67a783          	lw	a5,1206(a5) # 800088f0 <ticks>
    80002442:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    80002446:	8526                	mv	a0,s1
    80002448:	fffff097          	auipc	ra,0xfffff
    8000244c:	83e080e7          	jalr	-1986(ra) # 80000c86 <release>
  sched();
    80002450:	00000097          	auipc	ra,0x0
    80002454:	cf0080e7          	jalr	-784(ra) # 80002140 <sched>
  panic("zombie exit");
    80002458:	00006517          	auipc	a0,0x6
    8000245c:	e1050513          	add	a0,a0,-496 # 80008268 <digits+0x228>
    80002460:	ffffe097          	auipc	ra,0xffffe
    80002464:	0dc080e7          	jalr	220(ra) # 8000053c <panic>

0000000080002468 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002468:	7179                	add	sp,sp,-48
    8000246a:	f406                	sd	ra,40(sp)
    8000246c:	f022                	sd	s0,32(sp)
    8000246e:	ec26                	sd	s1,24(sp)
    80002470:	e84a                	sd	s2,16(sp)
    80002472:	e44e                	sd	s3,8(sp)
    80002474:	1800                	add	s0,sp,48
    80002476:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002478:	0000f497          	auipc	s1,0xf
    8000247c:	b1848493          	add	s1,s1,-1256 # 80010f90 <proc>
    80002480:	00015997          	auipc	s3,0x15
    80002484:	d1098993          	add	s3,s3,-752 # 80017190 <tickslock>
  {
    acquire(&p->lock);
    80002488:	8526                	mv	a0,s1
    8000248a:	ffffe097          	auipc	ra,0xffffe
    8000248e:	748080e7          	jalr	1864(ra) # 80000bd2 <acquire>
    if (p->pid == pid)
    80002492:	589c                	lw	a5,48(s1)
    80002494:	01278d63          	beq	a5,s2,800024ae <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002498:	8526                	mv	a0,s1
    8000249a:	ffffe097          	auipc	ra,0xffffe
    8000249e:	7ec080e7          	jalr	2028(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800024a2:	18848493          	add	s1,s1,392
    800024a6:	ff3491e3          	bne	s1,s3,80002488 <kill+0x20>
  }
  return -1;
    800024aa:	557d                	li	a0,-1
    800024ac:	a829                	j	800024c6 <kill+0x5e>
      p->killed = 1;
    800024ae:	4785                	li	a5,1
    800024b0:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800024b2:	4c98                	lw	a4,24(s1)
    800024b4:	4789                	li	a5,2
    800024b6:	00f70f63          	beq	a4,a5,800024d4 <kill+0x6c>
      release(&p->lock);
    800024ba:	8526                	mv	a0,s1
    800024bc:	ffffe097          	auipc	ra,0xffffe
    800024c0:	7ca080e7          	jalr	1994(ra) # 80000c86 <release>
      return 0;
    800024c4:	4501                	li	a0,0
}
    800024c6:	70a2                	ld	ra,40(sp)
    800024c8:	7402                	ld	s0,32(sp)
    800024ca:	64e2                	ld	s1,24(sp)
    800024cc:	6942                	ld	s2,16(sp)
    800024ce:	69a2                	ld	s3,8(sp)
    800024d0:	6145                	add	sp,sp,48
    800024d2:	8082                	ret
        p->state = RUNNABLE;
    800024d4:	478d                	li	a5,3
    800024d6:	cc9c                	sw	a5,24(s1)
    800024d8:	b7cd                	j	800024ba <kill+0x52>

00000000800024da <setkilled>:

void setkilled(struct proc *p)
{
    800024da:	1101                	add	sp,sp,-32
    800024dc:	ec06                	sd	ra,24(sp)
    800024de:	e822                	sd	s0,16(sp)
    800024e0:	e426                	sd	s1,8(sp)
    800024e2:	1000                	add	s0,sp,32
    800024e4:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800024e6:	ffffe097          	auipc	ra,0xffffe
    800024ea:	6ec080e7          	jalr	1772(ra) # 80000bd2 <acquire>
  p->killed = 1;
    800024ee:	4785                	li	a5,1
    800024f0:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800024f2:	8526                	mv	a0,s1
    800024f4:	ffffe097          	auipc	ra,0xffffe
    800024f8:	792080e7          	jalr	1938(ra) # 80000c86 <release>
}
    800024fc:	60e2                	ld	ra,24(sp)
    800024fe:	6442                	ld	s0,16(sp)
    80002500:	64a2                	ld	s1,8(sp)
    80002502:	6105                	add	sp,sp,32
    80002504:	8082                	ret

0000000080002506 <killed>:

int killed(struct proc *p)
{
    80002506:	1101                	add	sp,sp,-32
    80002508:	ec06                	sd	ra,24(sp)
    8000250a:	e822                	sd	s0,16(sp)
    8000250c:	e426                	sd	s1,8(sp)
    8000250e:	e04a                	sd	s2,0(sp)
    80002510:	1000                	add	s0,sp,32
    80002512:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002514:	ffffe097          	auipc	ra,0xffffe
    80002518:	6be080e7          	jalr	1726(ra) # 80000bd2 <acquire>
  k = p->killed;
    8000251c:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002520:	8526                	mv	a0,s1
    80002522:	ffffe097          	auipc	ra,0xffffe
    80002526:	764080e7          	jalr	1892(ra) # 80000c86 <release>
  return k;
}
    8000252a:	854a                	mv	a0,s2
    8000252c:	60e2                	ld	ra,24(sp)
    8000252e:	6442                	ld	s0,16(sp)
    80002530:	64a2                	ld	s1,8(sp)
    80002532:	6902                	ld	s2,0(sp)
    80002534:	6105                	add	sp,sp,32
    80002536:	8082                	ret

0000000080002538 <wait>:
{
    80002538:	715d                	add	sp,sp,-80
    8000253a:	e486                	sd	ra,72(sp)
    8000253c:	e0a2                	sd	s0,64(sp)
    8000253e:	fc26                	sd	s1,56(sp)
    80002540:	f84a                	sd	s2,48(sp)
    80002542:	f44e                	sd	s3,40(sp)
    80002544:	f052                	sd	s4,32(sp)
    80002546:	ec56                	sd	s5,24(sp)
    80002548:	e85a                	sd	s6,16(sp)
    8000254a:	e45e                	sd	s7,8(sp)
    8000254c:	e062                	sd	s8,0(sp)
    8000254e:	0880                	add	s0,sp,80
    80002550:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002552:	fffff097          	auipc	ra,0xfffff
    80002556:	47e080e7          	jalr	1150(ra) # 800019d0 <myproc>
    8000255a:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000255c:	0000e517          	auipc	a0,0xe
    80002560:	61c50513          	add	a0,a0,1564 # 80010b78 <wait_lock>
    80002564:	ffffe097          	auipc	ra,0xffffe
    80002568:	66e080e7          	jalr	1646(ra) # 80000bd2 <acquire>
    havekids = 0;
    8000256c:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    8000256e:	4a15                	li	s4,5
        havekids = 1;
    80002570:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002572:	00015997          	auipc	s3,0x15
    80002576:	c1e98993          	add	s3,s3,-994 # 80017190 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000257a:	0000ec17          	auipc	s8,0xe
    8000257e:	5fec0c13          	add	s8,s8,1534 # 80010b78 <wait_lock>
    80002582:	a0d1                	j	80002646 <wait+0x10e>
          pid = pp->pid;
    80002584:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002588:	000b0e63          	beqz	s6,800025a4 <wait+0x6c>
    8000258c:	4691                	li	a3,4
    8000258e:	02c48613          	add	a2,s1,44
    80002592:	85da                	mv	a1,s6
    80002594:	05093503          	ld	a0,80(s2)
    80002598:	fffff097          	auipc	ra,0xfffff
    8000259c:	088080e7          	jalr	136(ra) # 80001620 <copyout>
    800025a0:	04054163          	bltz	a0,800025e2 <wait+0xaa>
          freeproc(pp);
    800025a4:	8526                	mv	a0,s1
    800025a6:	fffff097          	auipc	ra,0xfffff
    800025aa:	5dc080e7          	jalr	1500(ra) # 80001b82 <freeproc>
          release(&pp->lock);
    800025ae:	8526                	mv	a0,s1
    800025b0:	ffffe097          	auipc	ra,0xffffe
    800025b4:	6d6080e7          	jalr	1750(ra) # 80000c86 <release>
          release(&wait_lock);
    800025b8:	0000e517          	auipc	a0,0xe
    800025bc:	5c050513          	add	a0,a0,1472 # 80010b78 <wait_lock>
    800025c0:	ffffe097          	auipc	ra,0xffffe
    800025c4:	6c6080e7          	jalr	1734(ra) # 80000c86 <release>
}
    800025c8:	854e                	mv	a0,s3
    800025ca:	60a6                	ld	ra,72(sp)
    800025cc:	6406                	ld	s0,64(sp)
    800025ce:	74e2                	ld	s1,56(sp)
    800025d0:	7942                	ld	s2,48(sp)
    800025d2:	79a2                	ld	s3,40(sp)
    800025d4:	7a02                	ld	s4,32(sp)
    800025d6:	6ae2                	ld	s5,24(sp)
    800025d8:	6b42                	ld	s6,16(sp)
    800025da:	6ba2                	ld	s7,8(sp)
    800025dc:	6c02                	ld	s8,0(sp)
    800025de:	6161                	add	sp,sp,80
    800025e0:	8082                	ret
            release(&pp->lock);
    800025e2:	8526                	mv	a0,s1
    800025e4:	ffffe097          	auipc	ra,0xffffe
    800025e8:	6a2080e7          	jalr	1698(ra) # 80000c86 <release>
            release(&wait_lock);
    800025ec:	0000e517          	auipc	a0,0xe
    800025f0:	58c50513          	add	a0,a0,1420 # 80010b78 <wait_lock>
    800025f4:	ffffe097          	auipc	ra,0xffffe
    800025f8:	692080e7          	jalr	1682(ra) # 80000c86 <release>
            return -1;
    800025fc:	59fd                	li	s3,-1
    800025fe:	b7e9                	j	800025c8 <wait+0x90>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002600:	18848493          	add	s1,s1,392
    80002604:	03348463          	beq	s1,s3,8000262c <wait+0xf4>
      if (pp->parent == p)
    80002608:	7c9c                	ld	a5,56(s1)
    8000260a:	ff279be3          	bne	a5,s2,80002600 <wait+0xc8>
        acquire(&pp->lock);
    8000260e:	8526                	mv	a0,s1
    80002610:	ffffe097          	auipc	ra,0xffffe
    80002614:	5c2080e7          	jalr	1474(ra) # 80000bd2 <acquire>
        if (pp->state == ZOMBIE)
    80002618:	4c9c                	lw	a5,24(s1)
    8000261a:	f74785e3          	beq	a5,s4,80002584 <wait+0x4c>
        release(&pp->lock);
    8000261e:	8526                	mv	a0,s1
    80002620:	ffffe097          	auipc	ra,0xffffe
    80002624:	666080e7          	jalr	1638(ra) # 80000c86 <release>
        havekids = 1;
    80002628:	8756                	mv	a4,s5
    8000262a:	bfd9                	j	80002600 <wait+0xc8>
    if (!havekids || killed(p))
    8000262c:	c31d                	beqz	a4,80002652 <wait+0x11a>
    8000262e:	854a                	mv	a0,s2
    80002630:	00000097          	auipc	ra,0x0
    80002634:	ed6080e7          	jalr	-298(ra) # 80002506 <killed>
    80002638:	ed09                	bnez	a0,80002652 <wait+0x11a>
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000263a:	85e2                	mv	a1,s8
    8000263c:	854a                	mv	a0,s2
    8000263e:	00000097          	auipc	ra,0x0
    80002642:	c14080e7          	jalr	-1004(ra) # 80002252 <sleep>
    havekids = 0;
    80002646:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002648:	0000f497          	auipc	s1,0xf
    8000264c:	94848493          	add	s1,s1,-1720 # 80010f90 <proc>
    80002650:	bf65                	j	80002608 <wait+0xd0>
      release(&wait_lock);
    80002652:	0000e517          	auipc	a0,0xe
    80002656:	52650513          	add	a0,a0,1318 # 80010b78 <wait_lock>
    8000265a:	ffffe097          	auipc	ra,0xffffe
    8000265e:	62c080e7          	jalr	1580(ra) # 80000c86 <release>
      return -1;
    80002662:	59fd                	li	s3,-1
    80002664:	b795                	j	800025c8 <wait+0x90>

0000000080002666 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002666:	7179                	add	sp,sp,-48
    80002668:	f406                	sd	ra,40(sp)
    8000266a:	f022                	sd	s0,32(sp)
    8000266c:	ec26                	sd	s1,24(sp)
    8000266e:	e84a                	sd	s2,16(sp)
    80002670:	e44e                	sd	s3,8(sp)
    80002672:	e052                	sd	s4,0(sp)
    80002674:	1800                	add	s0,sp,48
    80002676:	84aa                	mv	s1,a0
    80002678:	892e                	mv	s2,a1
    8000267a:	89b2                	mv	s3,a2
    8000267c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000267e:	fffff097          	auipc	ra,0xfffff
    80002682:	352080e7          	jalr	850(ra) # 800019d0 <myproc>
  if (user_dst)
    80002686:	c08d                	beqz	s1,800026a8 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002688:	86d2                	mv	a3,s4
    8000268a:	864e                	mv	a2,s3
    8000268c:	85ca                	mv	a1,s2
    8000268e:	6928                	ld	a0,80(a0)
    80002690:	fffff097          	auipc	ra,0xfffff
    80002694:	f90080e7          	jalr	-112(ra) # 80001620 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002698:	70a2                	ld	ra,40(sp)
    8000269a:	7402                	ld	s0,32(sp)
    8000269c:	64e2                	ld	s1,24(sp)
    8000269e:	6942                	ld	s2,16(sp)
    800026a0:	69a2                	ld	s3,8(sp)
    800026a2:	6a02                	ld	s4,0(sp)
    800026a4:	6145                	add	sp,sp,48
    800026a6:	8082                	ret
    memmove((char *)dst, src, len);
    800026a8:	000a061b          	sext.w	a2,s4
    800026ac:	85ce                	mv	a1,s3
    800026ae:	854a                	mv	a0,s2
    800026b0:	ffffe097          	auipc	ra,0xffffe
    800026b4:	67a080e7          	jalr	1658(ra) # 80000d2a <memmove>
    return 0;
    800026b8:	8526                	mv	a0,s1
    800026ba:	bff9                	j	80002698 <either_copyout+0x32>

00000000800026bc <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800026bc:	7179                	add	sp,sp,-48
    800026be:	f406                	sd	ra,40(sp)
    800026c0:	f022                	sd	s0,32(sp)
    800026c2:	ec26                	sd	s1,24(sp)
    800026c4:	e84a                	sd	s2,16(sp)
    800026c6:	e44e                	sd	s3,8(sp)
    800026c8:	e052                	sd	s4,0(sp)
    800026ca:	1800                	add	s0,sp,48
    800026cc:	892a                	mv	s2,a0
    800026ce:	84ae                	mv	s1,a1
    800026d0:	89b2                	mv	s3,a2
    800026d2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026d4:	fffff097          	auipc	ra,0xfffff
    800026d8:	2fc080e7          	jalr	764(ra) # 800019d0 <myproc>
  if (user_src)
    800026dc:	c08d                	beqz	s1,800026fe <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    800026de:	86d2                	mv	a3,s4
    800026e0:	864e                	mv	a2,s3
    800026e2:	85ca                	mv	a1,s2
    800026e4:	6928                	ld	a0,80(a0)
    800026e6:	fffff097          	auipc	ra,0xfffff
    800026ea:	036080e7          	jalr	54(ra) # 8000171c <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    800026ee:	70a2                	ld	ra,40(sp)
    800026f0:	7402                	ld	s0,32(sp)
    800026f2:	64e2                	ld	s1,24(sp)
    800026f4:	6942                	ld	s2,16(sp)
    800026f6:	69a2                	ld	s3,8(sp)
    800026f8:	6a02                	ld	s4,0(sp)
    800026fa:	6145                	add	sp,sp,48
    800026fc:	8082                	ret
    memmove(dst, (char *)src, len);
    800026fe:	000a061b          	sext.w	a2,s4
    80002702:	85ce                	mv	a1,s3
    80002704:	854a                	mv	a0,s2
    80002706:	ffffe097          	auipc	ra,0xffffe
    8000270a:	624080e7          	jalr	1572(ra) # 80000d2a <memmove>
    return 0;
    8000270e:	8526                	mv	a0,s1
    80002710:	bff9                	j	800026ee <either_copyin+0x32>

0000000080002712 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002712:	715d                	add	sp,sp,-80
    80002714:	e486                	sd	ra,72(sp)
    80002716:	e0a2                	sd	s0,64(sp)
    80002718:	fc26                	sd	s1,56(sp)
    8000271a:	f84a                	sd	s2,48(sp)
    8000271c:	f44e                	sd	s3,40(sp)
    8000271e:	f052                	sd	s4,32(sp)
    80002720:	ec56                	sd	s5,24(sp)
    80002722:	e85a                	sd	s6,16(sp)
    80002724:	e45e                	sd	s7,8(sp)
    80002726:	0880                	add	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002728:	00006517          	auipc	a0,0x6
    8000272c:	9a050513          	add	a0,a0,-1632 # 800080c8 <digits+0x88>
    80002730:	ffffe097          	auipc	ra,0xffffe
    80002734:	e56080e7          	jalr	-426(ra) # 80000586 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002738:	0000f497          	auipc	s1,0xf
    8000273c:	9b048493          	add	s1,s1,-1616 # 800110e8 <proc+0x158>
    80002740:	00015917          	auipc	s2,0x15
    80002744:	ba890913          	add	s2,s2,-1112 # 800172e8 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002748:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000274a:	00006997          	auipc	s3,0x6
    8000274e:	b2e98993          	add	s3,s3,-1234 # 80008278 <digits+0x238>
    printf("%d %s %s", p->pid, state, p->name);
    80002752:	00006a97          	auipc	s5,0x6
    80002756:	b2ea8a93          	add	s5,s5,-1234 # 80008280 <digits+0x240>
    printf("\n");
    8000275a:	00006a17          	auipc	s4,0x6
    8000275e:	96ea0a13          	add	s4,s4,-1682 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002762:	00006b97          	auipc	s7,0x6
    80002766:	b5eb8b93          	add	s7,s7,-1186 # 800082c0 <states.0>
    8000276a:	a00d                	j	8000278c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000276c:	ed86a583          	lw	a1,-296(a3)
    80002770:	8556                	mv	a0,s5
    80002772:	ffffe097          	auipc	ra,0xffffe
    80002776:	e14080e7          	jalr	-492(ra) # 80000586 <printf>
    printf("\n");
    8000277a:	8552                	mv	a0,s4
    8000277c:	ffffe097          	auipc	ra,0xffffe
    80002780:	e0a080e7          	jalr	-502(ra) # 80000586 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002784:	18848493          	add	s1,s1,392
    80002788:	03248263          	beq	s1,s2,800027ac <procdump+0x9a>
    if (p->state == UNUSED)
    8000278c:	86a6                	mv	a3,s1
    8000278e:	ec04a783          	lw	a5,-320(s1)
    80002792:	dbed                	beqz	a5,80002784 <procdump+0x72>
      state = "???";
    80002794:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002796:	fcfb6be3          	bltu	s6,a5,8000276c <procdump+0x5a>
    8000279a:	02079713          	sll	a4,a5,0x20
    8000279e:	01d75793          	srl	a5,a4,0x1d
    800027a2:	97de                	add	a5,a5,s7
    800027a4:	6390                	ld	a2,0(a5)
    800027a6:	f279                	bnez	a2,8000276c <procdump+0x5a>
      state = "???";
    800027a8:	864e                	mv	a2,s3
    800027aa:	b7c9                	j	8000276c <procdump+0x5a>
  }
}
    800027ac:	60a6                	ld	ra,72(sp)
    800027ae:	6406                	ld	s0,64(sp)
    800027b0:	74e2                	ld	s1,56(sp)
    800027b2:	7942                	ld	s2,48(sp)
    800027b4:	79a2                	ld	s3,40(sp)
    800027b6:	7a02                	ld	s4,32(sp)
    800027b8:	6ae2                	ld	s5,24(sp)
    800027ba:	6b42                	ld	s6,16(sp)
    800027bc:	6ba2                	ld	s7,8(sp)
    800027be:	6161                	add	sp,sp,80
    800027c0:	8082                	ret

00000000800027c2 <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    800027c2:	711d                	add	sp,sp,-96
    800027c4:	ec86                	sd	ra,88(sp)
    800027c6:	e8a2                	sd	s0,80(sp)
    800027c8:	e4a6                	sd	s1,72(sp)
    800027ca:	e0ca                	sd	s2,64(sp)
    800027cc:	fc4e                	sd	s3,56(sp)
    800027ce:	f852                	sd	s4,48(sp)
    800027d0:	f456                	sd	s5,40(sp)
    800027d2:	f05a                	sd	s6,32(sp)
    800027d4:	ec5e                	sd	s7,24(sp)
    800027d6:	e862                	sd	s8,16(sp)
    800027d8:	e466                	sd	s9,8(sp)
    800027da:	e06a                	sd	s10,0(sp)
    800027dc:	1080                	add	s0,sp,96
    800027de:	8b2a                	mv	s6,a0
    800027e0:	8bae                	mv	s7,a1
    800027e2:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    800027e4:	fffff097          	auipc	ra,0xfffff
    800027e8:	1ec080e7          	jalr	492(ra) # 800019d0 <myproc>
    800027ec:	892a                	mv	s2,a0

  acquire(&wait_lock);
    800027ee:	0000e517          	auipc	a0,0xe
    800027f2:	38a50513          	add	a0,a0,906 # 80010b78 <wait_lock>
    800027f6:	ffffe097          	auipc	ra,0xffffe
    800027fa:	3dc080e7          	jalr	988(ra) # 80000bd2 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    800027fe:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    80002800:	4a15                	li	s4,5
        havekids = 1;
    80002802:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002804:	00015997          	auipc	s3,0x15
    80002808:	98c98993          	add	s3,s3,-1652 # 80017190 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000280c:	0000ed17          	auipc	s10,0xe
    80002810:	36cd0d13          	add	s10,s10,876 # 80010b78 <wait_lock>
    80002814:	a8e9                	j	800028ee <waitx+0x12c>
          pid = np->pid;
    80002816:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    8000281a:	1684a783          	lw	a5,360(s1)
    8000281e:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002822:	16c4a703          	lw	a4,364(s1)
    80002826:	9f3d                	addw	a4,a4,a5
    80002828:	1704a783          	lw	a5,368(s1)
    8000282c:	9f99                	subw	a5,a5,a4
    8000282e:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002832:	000b0e63          	beqz	s6,8000284e <waitx+0x8c>
    80002836:	4691                	li	a3,4
    80002838:	02c48613          	add	a2,s1,44
    8000283c:	85da                	mv	a1,s6
    8000283e:	05093503          	ld	a0,80(s2)
    80002842:	fffff097          	auipc	ra,0xfffff
    80002846:	dde080e7          	jalr	-546(ra) # 80001620 <copyout>
    8000284a:	04054363          	bltz	a0,80002890 <waitx+0xce>
          freeproc(np);
    8000284e:	8526                	mv	a0,s1
    80002850:	fffff097          	auipc	ra,0xfffff
    80002854:	332080e7          	jalr	818(ra) # 80001b82 <freeproc>
          release(&np->lock);
    80002858:	8526                	mv	a0,s1
    8000285a:	ffffe097          	auipc	ra,0xffffe
    8000285e:	42c080e7          	jalr	1068(ra) # 80000c86 <release>
          release(&wait_lock);
    80002862:	0000e517          	auipc	a0,0xe
    80002866:	31650513          	add	a0,a0,790 # 80010b78 <wait_lock>
    8000286a:	ffffe097          	auipc	ra,0xffffe
    8000286e:	41c080e7          	jalr	1052(ra) # 80000c86 <release>
  }
}
    80002872:	854e                	mv	a0,s3
    80002874:	60e6                	ld	ra,88(sp)
    80002876:	6446                	ld	s0,80(sp)
    80002878:	64a6                	ld	s1,72(sp)
    8000287a:	6906                	ld	s2,64(sp)
    8000287c:	79e2                	ld	s3,56(sp)
    8000287e:	7a42                	ld	s4,48(sp)
    80002880:	7aa2                	ld	s5,40(sp)
    80002882:	7b02                	ld	s6,32(sp)
    80002884:	6be2                	ld	s7,24(sp)
    80002886:	6c42                	ld	s8,16(sp)
    80002888:	6ca2                	ld	s9,8(sp)
    8000288a:	6d02                	ld	s10,0(sp)
    8000288c:	6125                	add	sp,sp,96
    8000288e:	8082                	ret
            release(&np->lock);
    80002890:	8526                	mv	a0,s1
    80002892:	ffffe097          	auipc	ra,0xffffe
    80002896:	3f4080e7          	jalr	1012(ra) # 80000c86 <release>
            release(&wait_lock);
    8000289a:	0000e517          	auipc	a0,0xe
    8000289e:	2de50513          	add	a0,a0,734 # 80010b78 <wait_lock>
    800028a2:	ffffe097          	auipc	ra,0xffffe
    800028a6:	3e4080e7          	jalr	996(ra) # 80000c86 <release>
            return -1;
    800028aa:	59fd                	li	s3,-1
    800028ac:	b7d9                	j	80002872 <waitx+0xb0>
    for (np = proc; np < &proc[NPROC]; np++)
    800028ae:	18848493          	add	s1,s1,392
    800028b2:	03348463          	beq	s1,s3,800028da <waitx+0x118>
      if (np->parent == p)
    800028b6:	7c9c                	ld	a5,56(s1)
    800028b8:	ff279be3          	bne	a5,s2,800028ae <waitx+0xec>
        acquire(&np->lock);
    800028bc:	8526                	mv	a0,s1
    800028be:	ffffe097          	auipc	ra,0xffffe
    800028c2:	314080e7          	jalr	788(ra) # 80000bd2 <acquire>
        if (np->state == ZOMBIE)
    800028c6:	4c9c                	lw	a5,24(s1)
    800028c8:	f54787e3          	beq	a5,s4,80002816 <waitx+0x54>
        release(&np->lock);
    800028cc:	8526                	mv	a0,s1
    800028ce:	ffffe097          	auipc	ra,0xffffe
    800028d2:	3b8080e7          	jalr	952(ra) # 80000c86 <release>
        havekids = 1;
    800028d6:	8756                	mv	a4,s5
    800028d8:	bfd9                	j	800028ae <waitx+0xec>
    if (!havekids || p->killed)
    800028da:	c305                	beqz	a4,800028fa <waitx+0x138>
    800028dc:	02892783          	lw	a5,40(s2)
    800028e0:	ef89                	bnez	a5,800028fa <waitx+0x138>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800028e2:	85ea                	mv	a1,s10
    800028e4:	854a                	mv	a0,s2
    800028e6:	00000097          	auipc	ra,0x0
    800028ea:	96c080e7          	jalr	-1684(ra) # 80002252 <sleep>
    havekids = 0;
    800028ee:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    800028f0:	0000e497          	auipc	s1,0xe
    800028f4:	6a048493          	add	s1,s1,1696 # 80010f90 <proc>
    800028f8:	bf7d                	j	800028b6 <waitx+0xf4>
      release(&wait_lock);
    800028fa:	0000e517          	auipc	a0,0xe
    800028fe:	27e50513          	add	a0,a0,638 # 80010b78 <wait_lock>
    80002902:	ffffe097          	auipc	ra,0xffffe
    80002906:	384080e7          	jalr	900(ra) # 80000c86 <release>
      return -1;
    8000290a:	59fd                	li	s3,-1
    8000290c:	b79d                	j	80002872 <waitx+0xb0>

000000008000290e <update_time>:

void update_time()
{
    8000290e:	7179                	add	sp,sp,-48
    80002910:	f406                	sd	ra,40(sp)
    80002912:	f022                	sd	s0,32(sp)
    80002914:	ec26                	sd	s1,24(sp)
    80002916:	e84a                	sd	s2,16(sp)
    80002918:	e44e                	sd	s3,8(sp)
    8000291a:	1800                	add	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    8000291c:	0000e497          	auipc	s1,0xe
    80002920:	67448493          	add	s1,s1,1652 # 80010f90 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002924:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    80002926:	00015917          	auipc	s2,0x15
    8000292a:	86a90913          	add	s2,s2,-1942 # 80017190 <tickslock>
    8000292e:	a811                	j	80002942 <update_time+0x34>
    {
      p->rtime++;
    }
    release(&p->lock);
    80002930:	8526                	mv	a0,s1
    80002932:	ffffe097          	auipc	ra,0xffffe
    80002936:	354080e7          	jalr	852(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000293a:	18848493          	add	s1,s1,392
    8000293e:	03248063          	beq	s1,s2,8000295e <update_time+0x50>
    acquire(&p->lock);
    80002942:	8526                	mv	a0,s1
    80002944:	ffffe097          	auipc	ra,0xffffe
    80002948:	28e080e7          	jalr	654(ra) # 80000bd2 <acquire>
    if (p->state == RUNNING)
    8000294c:	4c9c                	lw	a5,24(s1)
    8000294e:	ff3791e3          	bne	a5,s3,80002930 <update_time+0x22>
      p->rtime++;
    80002952:	1684a783          	lw	a5,360(s1)
    80002956:	2785                	addw	a5,a5,1
    80002958:	16f4a423          	sw	a5,360(s1)
    8000295c:	bfd1                	j	80002930 <update_time+0x22>
  }
    8000295e:	70a2                	ld	ra,40(sp)
    80002960:	7402                	ld	s0,32(sp)
    80002962:	64e2                	ld	s1,24(sp)
    80002964:	6942                	ld	s2,16(sp)
    80002966:	69a2                	ld	s3,8(sp)
    80002968:	6145                	add	sp,sp,48
    8000296a:	8082                	ret

000000008000296c <swtch>:
    8000296c:	00153023          	sd	ra,0(a0)
    80002970:	00253423          	sd	sp,8(a0)
    80002974:	e900                	sd	s0,16(a0)
    80002976:	ed04                	sd	s1,24(a0)
    80002978:	03253023          	sd	s2,32(a0)
    8000297c:	03353423          	sd	s3,40(a0)
    80002980:	03453823          	sd	s4,48(a0)
    80002984:	03553c23          	sd	s5,56(a0)
    80002988:	05653023          	sd	s6,64(a0)
    8000298c:	05753423          	sd	s7,72(a0)
    80002990:	05853823          	sd	s8,80(a0)
    80002994:	05953c23          	sd	s9,88(a0)
    80002998:	07a53023          	sd	s10,96(a0)
    8000299c:	07b53423          	sd	s11,104(a0)
    800029a0:	0005b083          	ld	ra,0(a1)
    800029a4:	0085b103          	ld	sp,8(a1)
    800029a8:	6980                	ld	s0,16(a1)
    800029aa:	6d84                	ld	s1,24(a1)
    800029ac:	0205b903          	ld	s2,32(a1)
    800029b0:	0285b983          	ld	s3,40(a1)
    800029b4:	0305ba03          	ld	s4,48(a1)
    800029b8:	0385ba83          	ld	s5,56(a1)
    800029bc:	0405bb03          	ld	s6,64(a1)
    800029c0:	0485bb83          	ld	s7,72(a1)
    800029c4:	0505bc03          	ld	s8,80(a1)
    800029c8:	0585bc83          	ld	s9,88(a1)
    800029cc:	0605bd03          	ld	s10,96(a1)
    800029d0:	0685bd83          	ld	s11,104(a1)
    800029d4:	8082                	ret

00000000800029d6 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    800029d6:	1141                	add	sp,sp,-16
    800029d8:	e406                	sd	ra,8(sp)
    800029da:	e022                	sd	s0,0(sp)
    800029dc:	0800                	add	s0,sp,16
  initlock(&tickslock, "time");
    800029de:	00006597          	auipc	a1,0x6
    800029e2:	91258593          	add	a1,a1,-1774 # 800082f0 <states.0+0x30>
    800029e6:	00014517          	auipc	a0,0x14
    800029ea:	7aa50513          	add	a0,a0,1962 # 80017190 <tickslock>
    800029ee:	ffffe097          	auipc	ra,0xffffe
    800029f2:	154080e7          	jalr	340(ra) # 80000b42 <initlock>
}
    800029f6:	60a2                	ld	ra,8(sp)
    800029f8:	6402                	ld	s0,0(sp)
    800029fa:	0141                	add	sp,sp,16
    800029fc:	8082                	ret

00000000800029fe <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    800029fe:	1141                	add	sp,sp,-16
    80002a00:	e422                	sd	s0,8(sp)
    80002a02:	0800                	add	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a04:	00003797          	auipc	a5,0x3
    80002a08:	66c78793          	add	a5,a5,1644 # 80006070 <kernelvec>
    80002a0c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002a10:	6422                	ld	s0,8(sp)
    80002a12:	0141                	add	sp,sp,16
    80002a14:	8082                	ret

0000000080002a16 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002a16:	1141                	add	sp,sp,-16
    80002a18:	e406                	sd	ra,8(sp)
    80002a1a:	e022                	sd	s0,0(sp)
    80002a1c:	0800                	add	s0,sp,16
  struct proc *p = myproc();
    80002a1e:	fffff097          	auipc	ra,0xfffff
    80002a22:	fb2080e7          	jalr	-78(ra) # 800019d0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a26:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002a2a:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a2c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002a30:	00004697          	auipc	a3,0x4
    80002a34:	5d068693          	add	a3,a3,1488 # 80007000 <_trampoline>
    80002a38:	00004717          	auipc	a4,0x4
    80002a3c:	5c870713          	add	a4,a4,1480 # 80007000 <_trampoline>
    80002a40:	8f15                	sub	a4,a4,a3
    80002a42:	040007b7          	lui	a5,0x4000
    80002a46:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002a48:	07b2                	sll	a5,a5,0xc
    80002a4a:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a4c:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002a50:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002a52:	18002673          	csrr	a2,satp
    80002a56:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002a58:	6d30                	ld	a2,88(a0)
    80002a5a:	6138                	ld	a4,64(a0)
    80002a5c:	6585                	lui	a1,0x1
    80002a5e:	972e                	add	a4,a4,a1
    80002a60:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a62:	6d38                	ld	a4,88(a0)
    80002a64:	00000617          	auipc	a2,0x0
    80002a68:	14260613          	add	a2,a2,322 # 80002ba6 <usertrap>
    80002a6c:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002a6e:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a70:	8612                	mv	a2,tp
    80002a72:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a74:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a78:	eff77713          	and	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a7c:	02076713          	or	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a80:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a84:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a86:	6f18                	ld	a4,24(a4)
    80002a88:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a8c:	6928                	ld	a0,80(a0)
    80002a8e:	8131                	srl	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002a90:	00004717          	auipc	a4,0x4
    80002a94:	60c70713          	add	a4,a4,1548 # 8000709c <userret>
    80002a98:	8f15                	sub	a4,a4,a3
    80002a9a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002a9c:	577d                	li	a4,-1
    80002a9e:	177e                	sll	a4,a4,0x3f
    80002aa0:	8d59                	or	a0,a0,a4
    80002aa2:	9782                	jalr	a5
}
    80002aa4:	60a2                	ld	ra,8(sp)
    80002aa6:	6402                	ld	s0,0(sp)
    80002aa8:	0141                	add	sp,sp,16
    80002aaa:	8082                	ret

0000000080002aac <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002aac:	1101                	add	sp,sp,-32
    80002aae:	ec06                	sd	ra,24(sp)
    80002ab0:	e822                	sd	s0,16(sp)
    80002ab2:	e426                	sd	s1,8(sp)
    80002ab4:	e04a                	sd	s2,0(sp)
    80002ab6:	1000                	add	s0,sp,32
  acquire(&tickslock);
    80002ab8:	00014917          	auipc	s2,0x14
    80002abc:	6d890913          	add	s2,s2,1752 # 80017190 <tickslock>
    80002ac0:	854a                	mv	a0,s2
    80002ac2:	ffffe097          	auipc	ra,0xffffe
    80002ac6:	110080e7          	jalr	272(ra) # 80000bd2 <acquire>
  ticks++;
    80002aca:	00006497          	auipc	s1,0x6
    80002ace:	e2648493          	add	s1,s1,-474 # 800088f0 <ticks>
    80002ad2:	409c                	lw	a5,0(s1)
    80002ad4:	2785                	addw	a5,a5,1
    80002ad6:	c09c                	sw	a5,0(s1)
  update_time();
    80002ad8:	00000097          	auipc	ra,0x0
    80002adc:	e36080e7          	jalr	-458(ra) # 8000290e <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80002ae0:	8526                	mv	a0,s1
    80002ae2:	fffff097          	auipc	ra,0xfffff
    80002ae6:	7d4080e7          	jalr	2004(ra) # 800022b6 <wakeup>
  release(&tickslock);
    80002aea:	854a                	mv	a0,s2
    80002aec:	ffffe097          	auipc	ra,0xffffe
    80002af0:	19a080e7          	jalr	410(ra) # 80000c86 <release>
}
    80002af4:	60e2                	ld	ra,24(sp)
    80002af6:	6442                	ld	s0,16(sp)
    80002af8:	64a2                	ld	s1,8(sp)
    80002afa:	6902                	ld	s2,0(sp)
    80002afc:	6105                	add	sp,sp,32
    80002afe:	8082                	ret

0000000080002b00 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b00:	142027f3          	csrr	a5,scause

    return 2;
  }
  else
  {
    return 0;
    80002b04:	4501                	li	a0,0
  if ((scause & 0x8000000000000000L) &&
    80002b06:	0807df63          	bgez	a5,80002ba4 <devintr+0xa4>
{
    80002b0a:	1101                	add	sp,sp,-32
    80002b0c:	ec06                	sd	ra,24(sp)
    80002b0e:	e822                	sd	s0,16(sp)
    80002b10:	e426                	sd	s1,8(sp)
    80002b12:	1000                	add	s0,sp,32
      (scause & 0xff) == 9)
    80002b14:	0ff7f713          	zext.b	a4,a5
  if ((scause & 0x8000000000000000L) &&
    80002b18:	46a5                	li	a3,9
    80002b1a:	00d70d63          	beq	a4,a3,80002b34 <devintr+0x34>
  else if (scause == 0x8000000000000001L)
    80002b1e:	577d                	li	a4,-1
    80002b20:	177e                	sll	a4,a4,0x3f
    80002b22:	0705                	add	a4,a4,1
    return 0;
    80002b24:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002b26:	04e78e63          	beq	a5,a4,80002b82 <devintr+0x82>
  }
}
    80002b2a:	60e2                	ld	ra,24(sp)
    80002b2c:	6442                	ld	s0,16(sp)
    80002b2e:	64a2                	ld	s1,8(sp)
    80002b30:	6105                	add	sp,sp,32
    80002b32:	8082                	ret
    int irq = plic_claim();
    80002b34:	00003097          	auipc	ra,0x3
    80002b38:	644080e7          	jalr	1604(ra) # 80006178 <plic_claim>
    80002b3c:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002b3e:	47a9                	li	a5,10
    80002b40:	02f50763          	beq	a0,a5,80002b6e <devintr+0x6e>
    else if (irq == VIRTIO0_IRQ)
    80002b44:	4785                	li	a5,1
    80002b46:	02f50963          	beq	a0,a5,80002b78 <devintr+0x78>
    return 1;
    80002b4a:	4505                	li	a0,1
    else if (irq)
    80002b4c:	dcf9                	beqz	s1,80002b2a <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    80002b4e:	85a6                	mv	a1,s1
    80002b50:	00005517          	auipc	a0,0x5
    80002b54:	7a850513          	add	a0,a0,1960 # 800082f8 <states.0+0x38>
    80002b58:	ffffe097          	auipc	ra,0xffffe
    80002b5c:	a2e080e7          	jalr	-1490(ra) # 80000586 <printf>
      plic_complete(irq);
    80002b60:	8526                	mv	a0,s1
    80002b62:	00003097          	auipc	ra,0x3
    80002b66:	63a080e7          	jalr	1594(ra) # 8000619c <plic_complete>
    return 1;
    80002b6a:	4505                	li	a0,1
    80002b6c:	bf7d                	j	80002b2a <devintr+0x2a>
      uartintr();
    80002b6e:	ffffe097          	auipc	ra,0xffffe
    80002b72:	e26080e7          	jalr	-474(ra) # 80000994 <uartintr>
    if (irq)
    80002b76:	b7ed                	j	80002b60 <devintr+0x60>
      virtio_disk_intr();
    80002b78:	00004097          	auipc	ra,0x4
    80002b7c:	aea080e7          	jalr	-1302(ra) # 80006662 <virtio_disk_intr>
    if (irq)
    80002b80:	b7c5                	j	80002b60 <devintr+0x60>
    if (cpuid() == 0)
    80002b82:	fffff097          	auipc	ra,0xfffff
    80002b86:	e22080e7          	jalr	-478(ra) # 800019a4 <cpuid>
    80002b8a:	c901                	beqz	a0,80002b9a <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b8c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b90:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b92:	14479073          	csrw	sip,a5
    return 2;
    80002b96:	4509                	li	a0,2
    80002b98:	bf49                	j	80002b2a <devintr+0x2a>
      clockintr();
    80002b9a:	00000097          	auipc	ra,0x0
    80002b9e:	f12080e7          	jalr	-238(ra) # 80002aac <clockintr>
    80002ba2:	b7ed                	j	80002b8c <devintr+0x8c>
}
    80002ba4:	8082                	ret

0000000080002ba6 <usertrap>:
{
    80002ba6:	7139                	add	sp,sp,-64
    80002ba8:	fc06                	sd	ra,56(sp)
    80002baa:	f822                	sd	s0,48(sp)
    80002bac:	f426                	sd	s1,40(sp)
    80002bae:	f04a                	sd	s2,32(sp)
    80002bb0:	ec4e                	sd	s3,24(sp)
    80002bb2:	e852                	sd	s4,16(sp)
    80002bb4:	e456                	sd	s5,8(sp)
    80002bb6:	0080                	add	s0,sp,64
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bb8:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002bbc:	1007f793          	and	a5,a5,256
    80002bc0:	efb5                	bnez	a5,80002c3c <usertrap+0x96>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bc2:	00003797          	auipc	a5,0x3
    80002bc6:	4ae78793          	add	a5,a5,1198 # 80006070 <kernelvec>
    80002bca:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002bce:	fffff097          	auipc	ra,0xfffff
    80002bd2:	e02080e7          	jalr	-510(ra) # 800019d0 <myproc>
    80002bd6:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002bd8:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bda:	14102773          	csrr	a4,sepc
    80002bde:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002be0:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002be4:	47a1                	li	a5,8
    80002be6:	06f70363          	beq	a4,a5,80002c4c <usertrap+0xa6>
  else if ((which_dev = devintr()) != 0)
    80002bea:	00000097          	auipc	ra,0x0
    80002bee:	f16080e7          	jalr	-234(ra) # 80002b00 <devintr>
    80002bf2:	892a                	mv	s2,a0
    80002bf4:	10051e63          	bnez	a0,80002d10 <usertrap+0x16a>
    80002bf8:	14202773          	csrr	a4,scause
    if (r_scause() == 0xf){ // Page write fault
    80002bfc:	47bd                	li	a5,15
    80002bfe:	0af70363          	beq	a4,a5,80002ca4 <usertrap+0xfe>
    80002c02:	142025f3          	csrr	a1,scause
      printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c06:	5890                	lw	a2,48(s1)
    80002c08:	00005517          	auipc	a0,0x5
    80002c0c:	74850513          	add	a0,a0,1864 # 80008350 <states.0+0x90>
    80002c10:	ffffe097          	auipc	ra,0xffffe
    80002c14:	976080e7          	jalr	-1674(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c18:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c1c:	14302673          	csrr	a2,stval
      printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c20:	00005517          	auipc	a0,0x5
    80002c24:	76050513          	add	a0,a0,1888 # 80008380 <states.0+0xc0>
    80002c28:	ffffe097          	auipc	ra,0xffffe
    80002c2c:	95e080e7          	jalr	-1698(ra) # 80000586 <printf>
      setkilled(p);
    80002c30:	8526                	mv	a0,s1
    80002c32:	00000097          	auipc	ra,0x0
    80002c36:	8a8080e7          	jalr	-1880(ra) # 800024da <setkilled>
    80002c3a:	a825                	j	80002c72 <usertrap+0xcc>
    panic("usertrap: not from user mode");
    80002c3c:	00005517          	auipc	a0,0x5
    80002c40:	6dc50513          	add	a0,a0,1756 # 80008318 <states.0+0x58>
    80002c44:	ffffe097          	auipc	ra,0xffffe
    80002c48:	8f8080e7          	jalr	-1800(ra) # 8000053c <panic>
    if (killed(p))
    80002c4c:	00000097          	auipc	ra,0x0
    80002c50:	8ba080e7          	jalr	-1862(ra) # 80002506 <killed>
    80002c54:	e131                	bnez	a0,80002c98 <usertrap+0xf2>
    p->trapframe->epc += 4;
    80002c56:	6cb8                	ld	a4,88(s1)
    80002c58:	6f1c                	ld	a5,24(a4)
    80002c5a:	0791                	add	a5,a5,4
    80002c5c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c5e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002c62:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c66:	10079073          	csrw	sstatus,a5
    syscall();
    80002c6a:	00000097          	auipc	ra,0x0
    80002c6e:	31a080e7          	jalr	794(ra) # 80002f84 <syscall>
  if (killed(p))
    80002c72:	8526                	mv	a0,s1
    80002c74:	00000097          	auipc	ra,0x0
    80002c78:	892080e7          	jalr	-1902(ra) # 80002506 <killed>
    80002c7c:	e14d                	bnez	a0,80002d1e <usertrap+0x178>
  usertrapret();
    80002c7e:	00000097          	auipc	ra,0x0
    80002c82:	d98080e7          	jalr	-616(ra) # 80002a16 <usertrapret>
}
    80002c86:	70e2                	ld	ra,56(sp)
    80002c88:	7442                	ld	s0,48(sp)
    80002c8a:	74a2                	ld	s1,40(sp)
    80002c8c:	7902                	ld	s2,32(sp)
    80002c8e:	69e2                	ld	s3,24(sp)
    80002c90:	6a42                	ld	s4,16(sp)
    80002c92:	6aa2                	ld	s5,8(sp)
    80002c94:	6121                	add	sp,sp,64
    80002c96:	8082                	ret
      exit(-1);
    80002c98:	557d                	li	a0,-1
    80002c9a:	fffff097          	auipc	ra,0xfffff
    80002c9e:	6ec080e7          	jalr	1772(ra) # 80002386 <exit>
    80002ca2:	bf55                	j	80002c56 <usertrap+0xb0>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ca4:	14302673          	csrr	a2,stval
      printf("Page fault %d %d \n", p->pid,  r_stval());
    80002ca8:	588c                	lw	a1,48(s1)
    80002caa:	00005517          	auipc	a0,0x5
    80002cae:	68e50513          	add	a0,a0,1678 # 80008338 <states.0+0x78>
    80002cb2:	ffffe097          	auipc	ra,0xffffe
    80002cb6:	8d4080e7          	jalr	-1836(ra) # 80000586 <printf>
    80002cba:	14302af3          	csrr	s5,stval
      pte_t * pte =walk(p->pagetable, va, 0);
    80002cbe:	4601                	li	a2,0
    80002cc0:	85d6                	mv	a1,s5
    80002cc2:	68a8                	ld	a0,80(s1)
    80002cc4:	ffffe097          	auipc	ra,0xffffe
    80002cc8:	2ec080e7          	jalr	748(ra) # 80000fb0 <walk>
    80002ccc:	89aa                	mv	s3,a0
      uint64 pa = PTE2PA(*pte);
    80002cce:	00053903          	ld	s2,0(a0)
    80002cd2:	00a95913          	srl	s2,s2,0xa
    80002cd6:	0932                	sll	s2,s2,0xc
      char* mem = kalloc();
    80002cd8:	ffffe097          	auipc	ra,0xffffe
    80002cdc:	e0a080e7          	jalr	-502(ra) # 80000ae2 <kalloc>
    80002ce0:	8a2a                	mv	s4,a0
      memmove(mem, (char*)PGROUNDDOWN(pa), PGSIZE);
    80002ce2:	6605                	lui	a2,0x1
    80002ce4:	85ca                	mv	a1,s2
    80002ce6:	ffffe097          	auipc	ra,0xffffe
    80002cea:	044080e7          	jalr	68(ra) # 80000d2a <memmove>
      uint flags = PTE_FLAGS(*pte);
    80002cee:	0009b703          	ld	a4,0(s3)
    80002cf2:	3ff77713          	and	a4,a4,1023
      mappages(p->pagetable, PGROUNDDOWN(va), PGSIZE, (uint64)mem, flags );
    80002cf6:	00476713          	or	a4,a4,4
    80002cfa:	86d2                	mv	a3,s4
    80002cfc:	6605                	lui	a2,0x1
    80002cfe:	75fd                	lui	a1,0xfffff
    80002d00:	00baf5b3          	and	a1,s5,a1
    80002d04:	68a8                	ld	a0,80(s1)
    80002d06:	ffffe097          	auipc	ra,0xffffe
    80002d0a:	392080e7          	jalr	914(ra) # 80001098 <mappages>
    80002d0e:	b795                	j	80002c72 <usertrap+0xcc>
  if (killed(p))
    80002d10:	8526                	mv	a0,s1
    80002d12:	fffff097          	auipc	ra,0xfffff
    80002d16:	7f4080e7          	jalr	2036(ra) # 80002506 <killed>
    80002d1a:	c901                	beqz	a0,80002d2a <usertrap+0x184>
    80002d1c:	a011                	j	80002d20 <usertrap+0x17a>
    80002d1e:	4901                	li	s2,0
    exit(-1);
    80002d20:	557d                	li	a0,-1
    80002d22:	fffff097          	auipc	ra,0xfffff
    80002d26:	664080e7          	jalr	1636(ra) # 80002386 <exit>
  if (which_dev == 2)
    80002d2a:	4789                	li	a5,2
    80002d2c:	f4f919e3          	bne	s2,a5,80002c7e <usertrap+0xd8>
    yield();
    80002d30:	fffff097          	auipc	ra,0xfffff
    80002d34:	4e6080e7          	jalr	1254(ra) # 80002216 <yield>
    80002d38:	b799                	j	80002c7e <usertrap+0xd8>

0000000080002d3a <kerneltrap>:
{
    80002d3a:	7179                	add	sp,sp,-48
    80002d3c:	f406                	sd	ra,40(sp)
    80002d3e:	f022                	sd	s0,32(sp)
    80002d40:	ec26                	sd	s1,24(sp)
    80002d42:	e84a                	sd	s2,16(sp)
    80002d44:	e44e                	sd	s3,8(sp)
    80002d46:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d48:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d4c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d50:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002d54:	1004f793          	and	a5,s1,256
    80002d58:	cb85                	beqz	a5,80002d88 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d5a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002d5e:	8b89                	and	a5,a5,2
  if (intr_get() != 0)
    80002d60:	ef85                	bnez	a5,80002d98 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002d62:	00000097          	auipc	ra,0x0
    80002d66:	d9e080e7          	jalr	-610(ra) # 80002b00 <devintr>
    80002d6a:	cd1d                	beqz	a0,80002da8 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d6c:	4789                	li	a5,2
    80002d6e:	06f50a63          	beq	a0,a5,80002de2 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d72:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d76:	10049073          	csrw	sstatus,s1
}
    80002d7a:	70a2                	ld	ra,40(sp)
    80002d7c:	7402                	ld	s0,32(sp)
    80002d7e:	64e2                	ld	s1,24(sp)
    80002d80:	6942                	ld	s2,16(sp)
    80002d82:	69a2                	ld	s3,8(sp)
    80002d84:	6145                	add	sp,sp,48
    80002d86:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002d88:	00005517          	auipc	a0,0x5
    80002d8c:	61850513          	add	a0,a0,1560 # 800083a0 <states.0+0xe0>
    80002d90:	ffffd097          	auipc	ra,0xffffd
    80002d94:	7ac080e7          	jalr	1964(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    80002d98:	00005517          	auipc	a0,0x5
    80002d9c:	63050513          	add	a0,a0,1584 # 800083c8 <states.0+0x108>
    80002da0:	ffffd097          	auipc	ra,0xffffd
    80002da4:	79c080e7          	jalr	1948(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    80002da8:	85ce                	mv	a1,s3
    80002daa:	00005517          	auipc	a0,0x5
    80002dae:	63e50513          	add	a0,a0,1598 # 800083e8 <states.0+0x128>
    80002db2:	ffffd097          	auipc	ra,0xffffd
    80002db6:	7d4080e7          	jalr	2004(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002dba:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002dbe:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002dc2:	00005517          	auipc	a0,0x5
    80002dc6:	63650513          	add	a0,a0,1590 # 800083f8 <states.0+0x138>
    80002dca:	ffffd097          	auipc	ra,0xffffd
    80002dce:	7bc080e7          	jalr	1980(ra) # 80000586 <printf>
    panic("kerneltrap");
    80002dd2:	00005517          	auipc	a0,0x5
    80002dd6:	63e50513          	add	a0,a0,1598 # 80008410 <states.0+0x150>
    80002dda:	ffffd097          	auipc	ra,0xffffd
    80002dde:	762080e7          	jalr	1890(ra) # 8000053c <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002de2:	fffff097          	auipc	ra,0xfffff
    80002de6:	bee080e7          	jalr	-1042(ra) # 800019d0 <myproc>
    80002dea:	d541                	beqz	a0,80002d72 <kerneltrap+0x38>
    80002dec:	fffff097          	auipc	ra,0xfffff
    80002df0:	be4080e7          	jalr	-1052(ra) # 800019d0 <myproc>
    80002df4:	4d18                	lw	a4,24(a0)
    80002df6:	4791                	li	a5,4
    80002df8:	f6f71de3          	bne	a4,a5,80002d72 <kerneltrap+0x38>
    yield();
    80002dfc:	fffff097          	auipc	ra,0xfffff
    80002e00:	41a080e7          	jalr	1050(ra) # 80002216 <yield>
    80002e04:	b7bd                	j	80002d72 <kerneltrap+0x38>

0000000080002e06 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002e06:	1101                	add	sp,sp,-32
    80002e08:	ec06                	sd	ra,24(sp)
    80002e0a:	e822                	sd	s0,16(sp)
    80002e0c:	e426                	sd	s1,8(sp)
    80002e0e:	1000                	add	s0,sp,32
    80002e10:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002e12:	fffff097          	auipc	ra,0xfffff
    80002e16:	bbe080e7          	jalr	-1090(ra) # 800019d0 <myproc>
  switch (n) {
    80002e1a:	4795                	li	a5,5
    80002e1c:	0497e163          	bltu	a5,s1,80002e5e <argraw+0x58>
    80002e20:	048a                	sll	s1,s1,0x2
    80002e22:	00005717          	auipc	a4,0x5
    80002e26:	62670713          	add	a4,a4,1574 # 80008448 <states.0+0x188>
    80002e2a:	94ba                	add	s1,s1,a4
    80002e2c:	409c                	lw	a5,0(s1)
    80002e2e:	97ba                	add	a5,a5,a4
    80002e30:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002e32:	6d3c                	ld	a5,88(a0)
    80002e34:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002e36:	60e2                	ld	ra,24(sp)
    80002e38:	6442                	ld	s0,16(sp)
    80002e3a:	64a2                	ld	s1,8(sp)
    80002e3c:	6105                	add	sp,sp,32
    80002e3e:	8082                	ret
    return p->trapframe->a1;
    80002e40:	6d3c                	ld	a5,88(a0)
    80002e42:	7fa8                	ld	a0,120(a5)
    80002e44:	bfcd                	j	80002e36 <argraw+0x30>
    return p->trapframe->a2;
    80002e46:	6d3c                	ld	a5,88(a0)
    80002e48:	63c8                	ld	a0,128(a5)
    80002e4a:	b7f5                	j	80002e36 <argraw+0x30>
    return p->trapframe->a3;
    80002e4c:	6d3c                	ld	a5,88(a0)
    80002e4e:	67c8                	ld	a0,136(a5)
    80002e50:	b7dd                	j	80002e36 <argraw+0x30>
    return p->trapframe->a4;
    80002e52:	6d3c                	ld	a5,88(a0)
    80002e54:	6bc8                	ld	a0,144(a5)
    80002e56:	b7c5                	j	80002e36 <argraw+0x30>
    return p->trapframe->a5;
    80002e58:	6d3c                	ld	a5,88(a0)
    80002e5a:	6fc8                	ld	a0,152(a5)
    80002e5c:	bfe9                	j	80002e36 <argraw+0x30>
  panic("argraw");
    80002e5e:	00005517          	auipc	a0,0x5
    80002e62:	5c250513          	add	a0,a0,1474 # 80008420 <states.0+0x160>
    80002e66:	ffffd097          	auipc	ra,0xffffd
    80002e6a:	6d6080e7          	jalr	1750(ra) # 8000053c <panic>

0000000080002e6e <fetchaddr>:
{
    80002e6e:	1101                	add	sp,sp,-32
    80002e70:	ec06                	sd	ra,24(sp)
    80002e72:	e822                	sd	s0,16(sp)
    80002e74:	e426                	sd	s1,8(sp)
    80002e76:	e04a                	sd	s2,0(sp)
    80002e78:	1000                	add	s0,sp,32
    80002e7a:	84aa                	mv	s1,a0
    80002e7c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002e7e:	fffff097          	auipc	ra,0xfffff
    80002e82:	b52080e7          	jalr	-1198(ra) # 800019d0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002e86:	653c                	ld	a5,72(a0)
    80002e88:	02f4f863          	bgeu	s1,a5,80002eb8 <fetchaddr+0x4a>
    80002e8c:	00848713          	add	a4,s1,8
    80002e90:	02e7e663          	bltu	a5,a4,80002ebc <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002e94:	46a1                	li	a3,8
    80002e96:	8626                	mv	a2,s1
    80002e98:	85ca                	mv	a1,s2
    80002e9a:	6928                	ld	a0,80(a0)
    80002e9c:	fffff097          	auipc	ra,0xfffff
    80002ea0:	880080e7          	jalr	-1920(ra) # 8000171c <copyin>
    80002ea4:	00a03533          	snez	a0,a0
    80002ea8:	40a00533          	neg	a0,a0
}
    80002eac:	60e2                	ld	ra,24(sp)
    80002eae:	6442                	ld	s0,16(sp)
    80002eb0:	64a2                	ld	s1,8(sp)
    80002eb2:	6902                	ld	s2,0(sp)
    80002eb4:	6105                	add	sp,sp,32
    80002eb6:	8082                	ret
    return -1;
    80002eb8:	557d                	li	a0,-1
    80002eba:	bfcd                	j	80002eac <fetchaddr+0x3e>
    80002ebc:	557d                	li	a0,-1
    80002ebe:	b7fd                	j	80002eac <fetchaddr+0x3e>

0000000080002ec0 <fetchstr>:
{
    80002ec0:	7179                	add	sp,sp,-48
    80002ec2:	f406                	sd	ra,40(sp)
    80002ec4:	f022                	sd	s0,32(sp)
    80002ec6:	ec26                	sd	s1,24(sp)
    80002ec8:	e84a                	sd	s2,16(sp)
    80002eca:	e44e                	sd	s3,8(sp)
    80002ecc:	1800                	add	s0,sp,48
    80002ece:	892a                	mv	s2,a0
    80002ed0:	84ae                	mv	s1,a1
    80002ed2:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ed4:	fffff097          	auipc	ra,0xfffff
    80002ed8:	afc080e7          	jalr	-1284(ra) # 800019d0 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002edc:	86ce                	mv	a3,s3
    80002ede:	864a                	mv	a2,s2
    80002ee0:	85a6                	mv	a1,s1
    80002ee2:	6928                	ld	a0,80(a0)
    80002ee4:	fffff097          	auipc	ra,0xfffff
    80002ee8:	8c6080e7          	jalr	-1850(ra) # 800017aa <copyinstr>
    80002eec:	00054e63          	bltz	a0,80002f08 <fetchstr+0x48>
  return strlen(buf);
    80002ef0:	8526                	mv	a0,s1
    80002ef2:	ffffe097          	auipc	ra,0xffffe
    80002ef6:	f56080e7          	jalr	-170(ra) # 80000e48 <strlen>
}
    80002efa:	70a2                	ld	ra,40(sp)
    80002efc:	7402                	ld	s0,32(sp)
    80002efe:	64e2                	ld	s1,24(sp)
    80002f00:	6942                	ld	s2,16(sp)
    80002f02:	69a2                	ld	s3,8(sp)
    80002f04:	6145                	add	sp,sp,48
    80002f06:	8082                	ret
    return -1;
    80002f08:	557d                	li	a0,-1
    80002f0a:	bfc5                	j	80002efa <fetchstr+0x3a>

0000000080002f0c <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002f0c:	1101                	add	sp,sp,-32
    80002f0e:	ec06                	sd	ra,24(sp)
    80002f10:	e822                	sd	s0,16(sp)
    80002f12:	e426                	sd	s1,8(sp)
    80002f14:	1000                	add	s0,sp,32
    80002f16:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f18:	00000097          	auipc	ra,0x0
    80002f1c:	eee080e7          	jalr	-274(ra) # 80002e06 <argraw>
    80002f20:	c088                	sw	a0,0(s1)
}
    80002f22:	60e2                	ld	ra,24(sp)
    80002f24:	6442                	ld	s0,16(sp)
    80002f26:	64a2                	ld	s1,8(sp)
    80002f28:	6105                	add	sp,sp,32
    80002f2a:	8082                	ret

0000000080002f2c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002f2c:	1101                	add	sp,sp,-32
    80002f2e:	ec06                	sd	ra,24(sp)
    80002f30:	e822                	sd	s0,16(sp)
    80002f32:	e426                	sd	s1,8(sp)
    80002f34:	1000                	add	s0,sp,32
    80002f36:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f38:	00000097          	auipc	ra,0x0
    80002f3c:	ece080e7          	jalr	-306(ra) # 80002e06 <argraw>
    80002f40:	e088                	sd	a0,0(s1)
}
    80002f42:	60e2                	ld	ra,24(sp)
    80002f44:	6442                	ld	s0,16(sp)
    80002f46:	64a2                	ld	s1,8(sp)
    80002f48:	6105                	add	sp,sp,32
    80002f4a:	8082                	ret

0000000080002f4c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002f4c:	7179                	add	sp,sp,-48
    80002f4e:	f406                	sd	ra,40(sp)
    80002f50:	f022                	sd	s0,32(sp)
    80002f52:	ec26                	sd	s1,24(sp)
    80002f54:	e84a                	sd	s2,16(sp)
    80002f56:	1800                	add	s0,sp,48
    80002f58:	84ae                	mv	s1,a1
    80002f5a:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002f5c:	fd840593          	add	a1,s0,-40
    80002f60:	00000097          	auipc	ra,0x0
    80002f64:	fcc080e7          	jalr	-52(ra) # 80002f2c <argaddr>
  return fetchstr(addr, buf, max);
    80002f68:	864a                	mv	a2,s2
    80002f6a:	85a6                	mv	a1,s1
    80002f6c:	fd843503          	ld	a0,-40(s0)
    80002f70:	00000097          	auipc	ra,0x0
    80002f74:	f50080e7          	jalr	-176(ra) # 80002ec0 <fetchstr>
}
    80002f78:	70a2                	ld	ra,40(sp)
    80002f7a:	7402                	ld	s0,32(sp)
    80002f7c:	64e2                	ld	s1,24(sp)
    80002f7e:	6942                	ld	s2,16(sp)
    80002f80:	6145                	add	sp,sp,48
    80002f82:	8082                	ret

0000000080002f84 <syscall>:
[SYS_setpriority] sys_setpriority,
};

void
syscall(void)
{
    80002f84:	1101                	add	sp,sp,-32
    80002f86:	ec06                	sd	ra,24(sp)
    80002f88:	e822                	sd	s0,16(sp)
    80002f8a:	e426                	sd	s1,8(sp)
    80002f8c:	e04a                	sd	s2,0(sp)
    80002f8e:	1000                	add	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002f90:	fffff097          	auipc	ra,0xfffff
    80002f94:	a40080e7          	jalr	-1472(ra) # 800019d0 <myproc>
    80002f98:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002f9a:	05853903          	ld	s2,88(a0)
    80002f9e:	0a893783          	ld	a5,168(s2)
    80002fa2:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002fa6:	37fd                	addw	a5,a5,-1
    80002fa8:	475d                	li	a4,23
    80002faa:	00f76f63          	bltu	a4,a5,80002fc8 <syscall+0x44>
    80002fae:	00369713          	sll	a4,a3,0x3
    80002fb2:	00005797          	auipc	a5,0x5
    80002fb6:	4ae78793          	add	a5,a5,1198 # 80008460 <syscalls>
    80002fba:	97ba                	add	a5,a5,a4
    80002fbc:	639c                	ld	a5,0(a5)
    80002fbe:	c789                	beqz	a5,80002fc8 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002fc0:	9782                	jalr	a5
    80002fc2:	06a93823          	sd	a0,112(s2)
    80002fc6:	a839                	j	80002fe4 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002fc8:	15848613          	add	a2,s1,344
    80002fcc:	588c                	lw	a1,48(s1)
    80002fce:	00005517          	auipc	a0,0x5
    80002fd2:	45a50513          	add	a0,a0,1114 # 80008428 <states.0+0x168>
    80002fd6:	ffffd097          	auipc	ra,0xffffd
    80002fda:	5b0080e7          	jalr	1456(ra) # 80000586 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002fde:	6cbc                	ld	a5,88(s1)
    80002fe0:	577d                	li	a4,-1
    80002fe2:	fbb8                	sd	a4,112(a5)
  }
}
    80002fe4:	60e2                	ld	ra,24(sp)
    80002fe6:	6442                	ld	s0,16(sp)
    80002fe8:	64a2                	ld	s1,8(sp)
    80002fea:	6902                	ld	s2,0(sp)
    80002fec:	6105                	add	sp,sp,32
    80002fee:	8082                	ret

0000000080002ff0 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002ff0:	1101                	add	sp,sp,-32
    80002ff2:	ec06                	sd	ra,24(sp)
    80002ff4:	e822                	sd	s0,16(sp)
    80002ff6:	1000                	add	s0,sp,32
  int n;
  argint(0, &n);
    80002ff8:	fec40593          	add	a1,s0,-20
    80002ffc:	4501                	li	a0,0
    80002ffe:	00000097          	auipc	ra,0x0
    80003002:	f0e080e7          	jalr	-242(ra) # 80002f0c <argint>
  exit(n);
    80003006:	fec42503          	lw	a0,-20(s0)
    8000300a:	fffff097          	auipc	ra,0xfffff
    8000300e:	37c080e7          	jalr	892(ra) # 80002386 <exit>
  return 0; // not reached
}
    80003012:	4501                	li	a0,0
    80003014:	60e2                	ld	ra,24(sp)
    80003016:	6442                	ld	s0,16(sp)
    80003018:	6105                	add	sp,sp,32
    8000301a:	8082                	ret

000000008000301c <sys_getpid>:

uint64
sys_getpid(void)
{
    8000301c:	1141                	add	sp,sp,-16
    8000301e:	e406                	sd	ra,8(sp)
    80003020:	e022                	sd	s0,0(sp)
    80003022:	0800                	add	s0,sp,16
  return myproc()->pid;
    80003024:	fffff097          	auipc	ra,0xfffff
    80003028:	9ac080e7          	jalr	-1620(ra) # 800019d0 <myproc>
}
    8000302c:	5908                	lw	a0,48(a0)
    8000302e:	60a2                	ld	ra,8(sp)
    80003030:	6402                	ld	s0,0(sp)
    80003032:	0141                	add	sp,sp,16
    80003034:	8082                	ret

0000000080003036 <sys_fork>:

uint64
sys_fork(void)
{
    80003036:	1141                	add	sp,sp,-16
    80003038:	e406                	sd	ra,8(sp)
    8000303a:	e022                	sd	s0,0(sp)
    8000303c:	0800                	add	s0,sp,16
  return fork();
    8000303e:	fffff097          	auipc	ra,0xfffff
    80003042:	d70080e7          	jalr	-656(ra) # 80001dae <fork>
}
    80003046:	60a2                	ld	ra,8(sp)
    80003048:	6402                	ld	s0,0(sp)
    8000304a:	0141                	add	sp,sp,16
    8000304c:	8082                	ret

000000008000304e <sys_wait>:

uint64
sys_wait(void)
{
    8000304e:	1101                	add	sp,sp,-32
    80003050:	ec06                	sd	ra,24(sp)
    80003052:	e822                	sd	s0,16(sp)
    80003054:	1000                	add	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80003056:	fe840593          	add	a1,s0,-24
    8000305a:	4501                	li	a0,0
    8000305c:	00000097          	auipc	ra,0x0
    80003060:	ed0080e7          	jalr	-304(ra) # 80002f2c <argaddr>
  return wait(p);
    80003064:	fe843503          	ld	a0,-24(s0)
    80003068:	fffff097          	auipc	ra,0xfffff
    8000306c:	4d0080e7          	jalr	1232(ra) # 80002538 <wait>
}
    80003070:	60e2                	ld	ra,24(sp)
    80003072:	6442                	ld	s0,16(sp)
    80003074:	6105                	add	sp,sp,32
    80003076:	8082                	ret

0000000080003078 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003078:	7179                	add	sp,sp,-48
    8000307a:	f406                	sd	ra,40(sp)
    8000307c:	f022                	sd	s0,32(sp)
    8000307e:	ec26                	sd	s1,24(sp)
    80003080:	1800                	add	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80003082:	fdc40593          	add	a1,s0,-36
    80003086:	4501                	li	a0,0
    80003088:	00000097          	auipc	ra,0x0
    8000308c:	e84080e7          	jalr	-380(ra) # 80002f0c <argint>
  addr = myproc()->sz;
    80003090:	fffff097          	auipc	ra,0xfffff
    80003094:	940080e7          	jalr	-1728(ra) # 800019d0 <myproc>
    80003098:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    8000309a:	fdc42503          	lw	a0,-36(s0)
    8000309e:	fffff097          	auipc	ra,0xfffff
    800030a2:	cb4080e7          	jalr	-844(ra) # 80001d52 <growproc>
    800030a6:	00054863          	bltz	a0,800030b6 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    800030aa:	8526                	mv	a0,s1
    800030ac:	70a2                	ld	ra,40(sp)
    800030ae:	7402                	ld	s0,32(sp)
    800030b0:	64e2                	ld	s1,24(sp)
    800030b2:	6145                	add	sp,sp,48
    800030b4:	8082                	ret
    return -1;
    800030b6:	54fd                	li	s1,-1
    800030b8:	bfcd                	j	800030aa <sys_sbrk+0x32>

00000000800030ba <sys_sleep>:

uint64
sys_sleep(void)
{
    800030ba:	7139                	add	sp,sp,-64
    800030bc:	fc06                	sd	ra,56(sp)
    800030be:	f822                	sd	s0,48(sp)
    800030c0:	f426                	sd	s1,40(sp)
    800030c2:	f04a                	sd	s2,32(sp)
    800030c4:	ec4e                	sd	s3,24(sp)
    800030c6:	0080                	add	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800030c8:	fcc40593          	add	a1,s0,-52
    800030cc:	4501                	li	a0,0
    800030ce:	00000097          	auipc	ra,0x0
    800030d2:	e3e080e7          	jalr	-450(ra) # 80002f0c <argint>
  acquire(&tickslock);
    800030d6:	00014517          	auipc	a0,0x14
    800030da:	0ba50513          	add	a0,a0,186 # 80017190 <tickslock>
    800030de:	ffffe097          	auipc	ra,0xffffe
    800030e2:	af4080e7          	jalr	-1292(ra) # 80000bd2 <acquire>
  ticks0 = ticks;
    800030e6:	00006917          	auipc	s2,0x6
    800030ea:	80a92903          	lw	s2,-2038(s2) # 800088f0 <ticks>
  while (ticks - ticks0 < n)
    800030ee:	fcc42783          	lw	a5,-52(s0)
    800030f2:	cf9d                	beqz	a5,80003130 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800030f4:	00014997          	auipc	s3,0x14
    800030f8:	09c98993          	add	s3,s3,156 # 80017190 <tickslock>
    800030fc:	00005497          	auipc	s1,0x5
    80003100:	7f448493          	add	s1,s1,2036 # 800088f0 <ticks>
    if (killed(myproc()))
    80003104:	fffff097          	auipc	ra,0xfffff
    80003108:	8cc080e7          	jalr	-1844(ra) # 800019d0 <myproc>
    8000310c:	fffff097          	auipc	ra,0xfffff
    80003110:	3fa080e7          	jalr	1018(ra) # 80002506 <killed>
    80003114:	ed15                	bnez	a0,80003150 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003116:	85ce                	mv	a1,s3
    80003118:	8526                	mv	a0,s1
    8000311a:	fffff097          	auipc	ra,0xfffff
    8000311e:	138080e7          	jalr	312(ra) # 80002252 <sleep>
  while (ticks - ticks0 < n)
    80003122:	409c                	lw	a5,0(s1)
    80003124:	412787bb          	subw	a5,a5,s2
    80003128:	fcc42703          	lw	a4,-52(s0)
    8000312c:	fce7ece3          	bltu	a5,a4,80003104 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003130:	00014517          	auipc	a0,0x14
    80003134:	06050513          	add	a0,a0,96 # 80017190 <tickslock>
    80003138:	ffffe097          	auipc	ra,0xffffe
    8000313c:	b4e080e7          	jalr	-1202(ra) # 80000c86 <release>
  return 0;
    80003140:	4501                	li	a0,0
}
    80003142:	70e2                	ld	ra,56(sp)
    80003144:	7442                	ld	s0,48(sp)
    80003146:	74a2                	ld	s1,40(sp)
    80003148:	7902                	ld	s2,32(sp)
    8000314a:	69e2                	ld	s3,24(sp)
    8000314c:	6121                	add	sp,sp,64
    8000314e:	8082                	ret
      release(&tickslock);
    80003150:	00014517          	auipc	a0,0x14
    80003154:	04050513          	add	a0,a0,64 # 80017190 <tickslock>
    80003158:	ffffe097          	auipc	ra,0xffffe
    8000315c:	b2e080e7          	jalr	-1234(ra) # 80000c86 <release>
      return -1;
    80003160:	557d                	li	a0,-1
    80003162:	b7c5                	j	80003142 <sys_sleep+0x88>

0000000080003164 <sys_kill>:

uint64
sys_kill(void)
{
    80003164:	1101                	add	sp,sp,-32
    80003166:	ec06                	sd	ra,24(sp)
    80003168:	e822                	sd	s0,16(sp)
    8000316a:	1000                	add	s0,sp,32
  int pid;

  argint(0, &pid);
    8000316c:	fec40593          	add	a1,s0,-20
    80003170:	4501                	li	a0,0
    80003172:	00000097          	auipc	ra,0x0
    80003176:	d9a080e7          	jalr	-614(ra) # 80002f0c <argint>
  return kill(pid);
    8000317a:	fec42503          	lw	a0,-20(s0)
    8000317e:	fffff097          	auipc	ra,0xfffff
    80003182:	2ea080e7          	jalr	746(ra) # 80002468 <kill>
}
    80003186:	60e2                	ld	ra,24(sp)
    80003188:	6442                	ld	s0,16(sp)
    8000318a:	6105                	add	sp,sp,32
    8000318c:	8082                	ret

000000008000318e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000318e:	1101                	add	sp,sp,-32
    80003190:	ec06                	sd	ra,24(sp)
    80003192:	e822                	sd	s0,16(sp)
    80003194:	e426                	sd	s1,8(sp)
    80003196:	1000                	add	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003198:	00014517          	auipc	a0,0x14
    8000319c:	ff850513          	add	a0,a0,-8 # 80017190 <tickslock>
    800031a0:	ffffe097          	auipc	ra,0xffffe
    800031a4:	a32080e7          	jalr	-1486(ra) # 80000bd2 <acquire>
  xticks = ticks;
    800031a8:	00005497          	auipc	s1,0x5
    800031ac:	7484a483          	lw	s1,1864(s1) # 800088f0 <ticks>
  release(&tickslock);
    800031b0:	00014517          	auipc	a0,0x14
    800031b4:	fe050513          	add	a0,a0,-32 # 80017190 <tickslock>
    800031b8:	ffffe097          	auipc	ra,0xffffe
    800031bc:	ace080e7          	jalr	-1330(ra) # 80000c86 <release>
  return xticks;
}
    800031c0:	02049513          	sll	a0,s1,0x20
    800031c4:	9101                	srl	a0,a0,0x20
    800031c6:	60e2                	ld	ra,24(sp)
    800031c8:	6442                	ld	s0,16(sp)
    800031ca:	64a2                	ld	s1,8(sp)
    800031cc:	6105                	add	sp,sp,32
    800031ce:	8082                	ret

00000000800031d0 <sys_waitx>:

uint64
sys_waitx(void)
{
    800031d0:	7139                	add	sp,sp,-64
    800031d2:	fc06                	sd	ra,56(sp)
    800031d4:	f822                	sd	s0,48(sp)
    800031d6:	f426                	sd	s1,40(sp)
    800031d8:	f04a                	sd	s2,32(sp)
    800031da:	0080                	add	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    800031dc:	fd840593          	add	a1,s0,-40
    800031e0:	4501                	li	a0,0
    800031e2:	00000097          	auipc	ra,0x0
    800031e6:	d4a080e7          	jalr	-694(ra) # 80002f2c <argaddr>
  argaddr(1, &addr1); // user virtual memory
    800031ea:	fd040593          	add	a1,s0,-48
    800031ee:	4505                	li	a0,1
    800031f0:	00000097          	auipc	ra,0x0
    800031f4:	d3c080e7          	jalr	-708(ra) # 80002f2c <argaddr>
  argaddr(2, &addr2);
    800031f8:	fc840593          	add	a1,s0,-56
    800031fc:	4509                	li	a0,2
    800031fe:	00000097          	auipc	ra,0x0
    80003202:	d2e080e7          	jalr	-722(ra) # 80002f2c <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80003206:	fc040613          	add	a2,s0,-64
    8000320a:	fc440593          	add	a1,s0,-60
    8000320e:	fd843503          	ld	a0,-40(s0)
    80003212:	fffff097          	auipc	ra,0xfffff
    80003216:	5b0080e7          	jalr	1456(ra) # 800027c2 <waitx>
    8000321a:	892a                	mv	s2,a0
  struct proc *p = myproc();
    8000321c:	ffffe097          	auipc	ra,0xffffe
    80003220:	7b4080e7          	jalr	1972(ra) # 800019d0 <myproc>
    80003224:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003226:	4691                	li	a3,4
    80003228:	fc440613          	add	a2,s0,-60
    8000322c:	fd043583          	ld	a1,-48(s0)
    80003230:	6928                	ld	a0,80(a0)
    80003232:	ffffe097          	auipc	ra,0xffffe
    80003236:	3ee080e7          	jalr	1006(ra) # 80001620 <copyout>
    return -1;
    8000323a:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    8000323c:	00054f63          	bltz	a0,8000325a <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    80003240:	4691                	li	a3,4
    80003242:	fc040613          	add	a2,s0,-64
    80003246:	fc843583          	ld	a1,-56(s0)
    8000324a:	68a8                	ld	a0,80(s1)
    8000324c:	ffffe097          	auipc	ra,0xffffe
    80003250:	3d4080e7          	jalr	980(ra) # 80001620 <copyout>
    80003254:	00054a63          	bltz	a0,80003268 <sys_waitx+0x98>
    return -1;
  return ret;
    80003258:	87ca                	mv	a5,s2
}
    8000325a:	853e                	mv	a0,a5
    8000325c:	70e2                	ld	ra,56(sp)
    8000325e:	7442                	ld	s0,48(sp)
    80003260:	74a2                	ld	s1,40(sp)
    80003262:	7902                	ld	s2,32(sp)
    80003264:	6121                	add	sp,sp,64
    80003266:	8082                	ret
    return -1;
    80003268:	57fd                	li	a5,-1
    8000326a:	bfc5                	j	8000325a <sys_waitx+0x8a>

000000008000326c <sys_setpriority>:

uint64
sys_setpriority(void)
{
    8000326c:	7179                	add	sp,sp,-48
    8000326e:	f406                	sd	ra,40(sp)
    80003270:	f022                	sd	s0,32(sp)
    80003272:	ec26                	sd	s1,24(sp)
    80003274:	e84a                	sd	s2,16(sp)
    80003276:	1800                	add	s0,sp,48
  #ifdef SCHED_PBS
    int pid, priority;
    int old_priority = 0 ;
    argint(0, &pid);
    80003278:	fdc40593          	add	a1,s0,-36
    8000327c:	4501                	li	a0,0
    8000327e:	00000097          	auipc	ra,0x0
    80003282:	c8e080e7          	jalr	-882(ra) # 80002f0c <argint>
    argint(1, &priority);
    80003286:	fd840593          	add	a1,s0,-40
    8000328a:	4505                	li	a0,1
    8000328c:	00000097          	auipc	ra,0x0
    80003290:	c80080e7          	jalr	-896(ra) # 80002f0c <argint>
    if (priority < 0) priority = 0;
    80003294:	fd842783          	lw	a5,-40(s0)
    80003298:	0207cd63          	bltz	a5,800032d2 <sys_setpriority+0x66>
    if (priority > 100) priority = 100;
    8000329c:	06400713          	li	a4,100
    800032a0:	00f75663          	bge	a4,a5,800032ac <sys_setpriority+0x40>
    800032a4:	06400793          	li	a5,100
    800032a8:	fcf42c23          	sw	a5,-40(s0)
    for (int p_idx = 0; p_idx < NPROC; p_idx++){

      if (proc[p_idx].pid == pid){
    800032ac:	fdc42603          	lw	a2,-36(s0)
    800032b0:	0000e717          	auipc	a4,0xe
    800032b4:	d1070713          	add	a4,a4,-752 # 80010fc0 <proc+0x30>
    for (int p_idx = 0; p_idx < NPROC; p_idx++){
    800032b8:	4781                	li	a5,0
    800032ba:	04000593          	li	a1,64
      if (proc[p_idx].pid == pid){
    800032be:	4314                	lw	a3,0(a4)
    800032c0:	00c68c63          	beq	a3,a2,800032d8 <sys_setpriority+0x6c>
    for (int p_idx = 0; p_idx < NPROC; p_idx++){
    800032c4:	2785                	addw	a5,a5,1
    800032c6:	18870713          	add	a4,a4,392
    800032ca:	feb79ae3          	bne	a5,a1,800032be <sys_setpriority+0x52>
    int old_priority = 0 ;
    800032ce:	4901                	li	s2,0
    800032d0:	a835                	j	8000330c <sys_setpriority+0xa0>
    if (priority < 0) priority = 0;
    800032d2:	fc042c23          	sw	zero,-40(s0)
    if (priority > 100) priority = 100;
    800032d6:	bfd9                	j	800032ac <sys_setpriority+0x40>
        acquire(&proc[p_idx].lock);
    800032d8:	18800713          	li	a4,392
    800032dc:	02e787b3          	mul	a5,a5,a4
    800032e0:	0000e717          	auipc	a4,0xe
    800032e4:	cb070713          	add	a4,a4,-848 # 80010f90 <proc>
    800032e8:	00e784b3          	add	s1,a5,a4
    800032ec:	8526                	mv	a0,s1
    800032ee:	ffffe097          	auipc	ra,0xffffe
    800032f2:	8e4080e7          	jalr	-1820(ra) # 80000bd2 <acquire>
        old_priority = proc[p_idx].SP;
    800032f6:	1804a903          	lw	s2,384(s1)
        proc[p_idx].SP = priority;
    800032fa:	fd842783          	lw	a5,-40(s0)
    800032fe:	18f4a023          	sw	a5,384(s1)
        release(&proc[p_idx].lock);
    80003302:	8526                	mv	a0,s1
    80003304:	ffffe097          	auipc	ra,0xffffe
    80003308:	982080e7          	jalr	-1662(ra) # 80000c86 <release>
    }
    return old_priority;
  #else
    return 0;
  #endif
}
    8000330c:	854a                	mv	a0,s2
    8000330e:	70a2                	ld	ra,40(sp)
    80003310:	7402                	ld	s0,32(sp)
    80003312:	64e2                	ld	s1,24(sp)
    80003314:	6942                	ld	s2,16(sp)
    80003316:	6145                	add	sp,sp,48
    80003318:	8082                	ret

000000008000331a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000331a:	7179                	add	sp,sp,-48
    8000331c:	f406                	sd	ra,40(sp)
    8000331e:	f022                	sd	s0,32(sp)
    80003320:	ec26                	sd	s1,24(sp)
    80003322:	e84a                	sd	s2,16(sp)
    80003324:	e44e                	sd	s3,8(sp)
    80003326:	e052                	sd	s4,0(sp)
    80003328:	1800                	add	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000332a:	00005597          	auipc	a1,0x5
    8000332e:	1fe58593          	add	a1,a1,510 # 80008528 <syscalls+0xc8>
    80003332:	00014517          	auipc	a0,0x14
    80003336:	e7650513          	add	a0,a0,-394 # 800171a8 <bcache>
    8000333a:	ffffe097          	auipc	ra,0xffffe
    8000333e:	808080e7          	jalr	-2040(ra) # 80000b42 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003342:	0001c797          	auipc	a5,0x1c
    80003346:	e6678793          	add	a5,a5,-410 # 8001f1a8 <bcache+0x8000>
    8000334a:	0001c717          	auipc	a4,0x1c
    8000334e:	0c670713          	add	a4,a4,198 # 8001f410 <bcache+0x8268>
    80003352:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003356:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000335a:	00014497          	auipc	s1,0x14
    8000335e:	e6648493          	add	s1,s1,-410 # 800171c0 <bcache+0x18>
    b->next = bcache.head.next;
    80003362:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003364:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003366:	00005a17          	auipc	s4,0x5
    8000336a:	1caa0a13          	add	s4,s4,458 # 80008530 <syscalls+0xd0>
    b->next = bcache.head.next;
    8000336e:	2b893783          	ld	a5,696(s2)
    80003372:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003374:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003378:	85d2                	mv	a1,s4
    8000337a:	01048513          	add	a0,s1,16
    8000337e:	00001097          	auipc	ra,0x1
    80003382:	496080e7          	jalr	1174(ra) # 80004814 <initsleeplock>
    bcache.head.next->prev = b;
    80003386:	2b893783          	ld	a5,696(s2)
    8000338a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000338c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003390:	45848493          	add	s1,s1,1112
    80003394:	fd349de3          	bne	s1,s3,8000336e <binit+0x54>
  }
}
    80003398:	70a2                	ld	ra,40(sp)
    8000339a:	7402                	ld	s0,32(sp)
    8000339c:	64e2                	ld	s1,24(sp)
    8000339e:	6942                	ld	s2,16(sp)
    800033a0:	69a2                	ld	s3,8(sp)
    800033a2:	6a02                	ld	s4,0(sp)
    800033a4:	6145                	add	sp,sp,48
    800033a6:	8082                	ret

00000000800033a8 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800033a8:	7179                	add	sp,sp,-48
    800033aa:	f406                	sd	ra,40(sp)
    800033ac:	f022                	sd	s0,32(sp)
    800033ae:	ec26                	sd	s1,24(sp)
    800033b0:	e84a                	sd	s2,16(sp)
    800033b2:	e44e                	sd	s3,8(sp)
    800033b4:	1800                	add	s0,sp,48
    800033b6:	892a                	mv	s2,a0
    800033b8:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800033ba:	00014517          	auipc	a0,0x14
    800033be:	dee50513          	add	a0,a0,-530 # 800171a8 <bcache>
    800033c2:	ffffe097          	auipc	ra,0xffffe
    800033c6:	810080e7          	jalr	-2032(ra) # 80000bd2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800033ca:	0001c497          	auipc	s1,0x1c
    800033ce:	0964b483          	ld	s1,150(s1) # 8001f460 <bcache+0x82b8>
    800033d2:	0001c797          	auipc	a5,0x1c
    800033d6:	03e78793          	add	a5,a5,62 # 8001f410 <bcache+0x8268>
    800033da:	02f48f63          	beq	s1,a5,80003418 <bread+0x70>
    800033de:	873e                	mv	a4,a5
    800033e0:	a021                	j	800033e8 <bread+0x40>
    800033e2:	68a4                	ld	s1,80(s1)
    800033e4:	02e48a63          	beq	s1,a4,80003418 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800033e8:	449c                	lw	a5,8(s1)
    800033ea:	ff279ce3          	bne	a5,s2,800033e2 <bread+0x3a>
    800033ee:	44dc                	lw	a5,12(s1)
    800033f0:	ff3799e3          	bne	a5,s3,800033e2 <bread+0x3a>
      b->refcnt++;
    800033f4:	40bc                	lw	a5,64(s1)
    800033f6:	2785                	addw	a5,a5,1
    800033f8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800033fa:	00014517          	auipc	a0,0x14
    800033fe:	dae50513          	add	a0,a0,-594 # 800171a8 <bcache>
    80003402:	ffffe097          	auipc	ra,0xffffe
    80003406:	884080e7          	jalr	-1916(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    8000340a:	01048513          	add	a0,s1,16
    8000340e:	00001097          	auipc	ra,0x1
    80003412:	440080e7          	jalr	1088(ra) # 8000484e <acquiresleep>
      return b;
    80003416:	a8b9                	j	80003474 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003418:	0001c497          	auipc	s1,0x1c
    8000341c:	0404b483          	ld	s1,64(s1) # 8001f458 <bcache+0x82b0>
    80003420:	0001c797          	auipc	a5,0x1c
    80003424:	ff078793          	add	a5,a5,-16 # 8001f410 <bcache+0x8268>
    80003428:	00f48863          	beq	s1,a5,80003438 <bread+0x90>
    8000342c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000342e:	40bc                	lw	a5,64(s1)
    80003430:	cf81                	beqz	a5,80003448 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003432:	64a4                	ld	s1,72(s1)
    80003434:	fee49de3          	bne	s1,a4,8000342e <bread+0x86>
  panic("bget: no buffers");
    80003438:	00005517          	auipc	a0,0x5
    8000343c:	10050513          	add	a0,a0,256 # 80008538 <syscalls+0xd8>
    80003440:	ffffd097          	auipc	ra,0xffffd
    80003444:	0fc080e7          	jalr	252(ra) # 8000053c <panic>
      b->dev = dev;
    80003448:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000344c:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003450:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003454:	4785                	li	a5,1
    80003456:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003458:	00014517          	auipc	a0,0x14
    8000345c:	d5050513          	add	a0,a0,-688 # 800171a8 <bcache>
    80003460:	ffffe097          	auipc	ra,0xffffe
    80003464:	826080e7          	jalr	-2010(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80003468:	01048513          	add	a0,s1,16
    8000346c:	00001097          	auipc	ra,0x1
    80003470:	3e2080e7          	jalr	994(ra) # 8000484e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003474:	409c                	lw	a5,0(s1)
    80003476:	cb89                	beqz	a5,80003488 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003478:	8526                	mv	a0,s1
    8000347a:	70a2                	ld	ra,40(sp)
    8000347c:	7402                	ld	s0,32(sp)
    8000347e:	64e2                	ld	s1,24(sp)
    80003480:	6942                	ld	s2,16(sp)
    80003482:	69a2                	ld	s3,8(sp)
    80003484:	6145                	add	sp,sp,48
    80003486:	8082                	ret
    virtio_disk_rw(b, 0);
    80003488:	4581                	li	a1,0
    8000348a:	8526                	mv	a0,s1
    8000348c:	00003097          	auipc	ra,0x3
    80003490:	fa6080e7          	jalr	-90(ra) # 80006432 <virtio_disk_rw>
    b->valid = 1;
    80003494:	4785                	li	a5,1
    80003496:	c09c                	sw	a5,0(s1)
  return b;
    80003498:	b7c5                	j	80003478 <bread+0xd0>

000000008000349a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000349a:	1101                	add	sp,sp,-32
    8000349c:	ec06                	sd	ra,24(sp)
    8000349e:	e822                	sd	s0,16(sp)
    800034a0:	e426                	sd	s1,8(sp)
    800034a2:	1000                	add	s0,sp,32
    800034a4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800034a6:	0541                	add	a0,a0,16
    800034a8:	00001097          	auipc	ra,0x1
    800034ac:	440080e7          	jalr	1088(ra) # 800048e8 <holdingsleep>
    800034b0:	cd01                	beqz	a0,800034c8 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800034b2:	4585                	li	a1,1
    800034b4:	8526                	mv	a0,s1
    800034b6:	00003097          	auipc	ra,0x3
    800034ba:	f7c080e7          	jalr	-132(ra) # 80006432 <virtio_disk_rw>
}
    800034be:	60e2                	ld	ra,24(sp)
    800034c0:	6442                	ld	s0,16(sp)
    800034c2:	64a2                	ld	s1,8(sp)
    800034c4:	6105                	add	sp,sp,32
    800034c6:	8082                	ret
    panic("bwrite");
    800034c8:	00005517          	auipc	a0,0x5
    800034cc:	08850513          	add	a0,a0,136 # 80008550 <syscalls+0xf0>
    800034d0:	ffffd097          	auipc	ra,0xffffd
    800034d4:	06c080e7          	jalr	108(ra) # 8000053c <panic>

00000000800034d8 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800034d8:	1101                	add	sp,sp,-32
    800034da:	ec06                	sd	ra,24(sp)
    800034dc:	e822                	sd	s0,16(sp)
    800034de:	e426                	sd	s1,8(sp)
    800034e0:	e04a                	sd	s2,0(sp)
    800034e2:	1000                	add	s0,sp,32
    800034e4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800034e6:	01050913          	add	s2,a0,16
    800034ea:	854a                	mv	a0,s2
    800034ec:	00001097          	auipc	ra,0x1
    800034f0:	3fc080e7          	jalr	1020(ra) # 800048e8 <holdingsleep>
    800034f4:	c925                	beqz	a0,80003564 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    800034f6:	854a                	mv	a0,s2
    800034f8:	00001097          	auipc	ra,0x1
    800034fc:	3ac080e7          	jalr	940(ra) # 800048a4 <releasesleep>

  acquire(&bcache.lock);
    80003500:	00014517          	auipc	a0,0x14
    80003504:	ca850513          	add	a0,a0,-856 # 800171a8 <bcache>
    80003508:	ffffd097          	auipc	ra,0xffffd
    8000350c:	6ca080e7          	jalr	1738(ra) # 80000bd2 <acquire>
  b->refcnt--;
    80003510:	40bc                	lw	a5,64(s1)
    80003512:	37fd                	addw	a5,a5,-1
    80003514:	0007871b          	sext.w	a4,a5
    80003518:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000351a:	e71d                	bnez	a4,80003548 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000351c:	68b8                	ld	a4,80(s1)
    8000351e:	64bc                	ld	a5,72(s1)
    80003520:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80003522:	68b8                	ld	a4,80(s1)
    80003524:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003526:	0001c797          	auipc	a5,0x1c
    8000352a:	c8278793          	add	a5,a5,-894 # 8001f1a8 <bcache+0x8000>
    8000352e:	2b87b703          	ld	a4,696(a5)
    80003532:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003534:	0001c717          	auipc	a4,0x1c
    80003538:	edc70713          	add	a4,a4,-292 # 8001f410 <bcache+0x8268>
    8000353c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000353e:	2b87b703          	ld	a4,696(a5)
    80003542:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003544:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003548:	00014517          	auipc	a0,0x14
    8000354c:	c6050513          	add	a0,a0,-928 # 800171a8 <bcache>
    80003550:	ffffd097          	auipc	ra,0xffffd
    80003554:	736080e7          	jalr	1846(ra) # 80000c86 <release>
}
    80003558:	60e2                	ld	ra,24(sp)
    8000355a:	6442                	ld	s0,16(sp)
    8000355c:	64a2                	ld	s1,8(sp)
    8000355e:	6902                	ld	s2,0(sp)
    80003560:	6105                	add	sp,sp,32
    80003562:	8082                	ret
    panic("brelse");
    80003564:	00005517          	auipc	a0,0x5
    80003568:	ff450513          	add	a0,a0,-12 # 80008558 <syscalls+0xf8>
    8000356c:	ffffd097          	auipc	ra,0xffffd
    80003570:	fd0080e7          	jalr	-48(ra) # 8000053c <panic>

0000000080003574 <bpin>:

void
bpin(struct buf *b) {
    80003574:	1101                	add	sp,sp,-32
    80003576:	ec06                	sd	ra,24(sp)
    80003578:	e822                	sd	s0,16(sp)
    8000357a:	e426                	sd	s1,8(sp)
    8000357c:	1000                	add	s0,sp,32
    8000357e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003580:	00014517          	auipc	a0,0x14
    80003584:	c2850513          	add	a0,a0,-984 # 800171a8 <bcache>
    80003588:	ffffd097          	auipc	ra,0xffffd
    8000358c:	64a080e7          	jalr	1610(ra) # 80000bd2 <acquire>
  b->refcnt++;
    80003590:	40bc                	lw	a5,64(s1)
    80003592:	2785                	addw	a5,a5,1
    80003594:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003596:	00014517          	auipc	a0,0x14
    8000359a:	c1250513          	add	a0,a0,-1006 # 800171a8 <bcache>
    8000359e:	ffffd097          	auipc	ra,0xffffd
    800035a2:	6e8080e7          	jalr	1768(ra) # 80000c86 <release>
}
    800035a6:	60e2                	ld	ra,24(sp)
    800035a8:	6442                	ld	s0,16(sp)
    800035aa:	64a2                	ld	s1,8(sp)
    800035ac:	6105                	add	sp,sp,32
    800035ae:	8082                	ret

00000000800035b0 <bunpin>:

void
bunpin(struct buf *b) {
    800035b0:	1101                	add	sp,sp,-32
    800035b2:	ec06                	sd	ra,24(sp)
    800035b4:	e822                	sd	s0,16(sp)
    800035b6:	e426                	sd	s1,8(sp)
    800035b8:	1000                	add	s0,sp,32
    800035ba:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800035bc:	00014517          	auipc	a0,0x14
    800035c0:	bec50513          	add	a0,a0,-1044 # 800171a8 <bcache>
    800035c4:	ffffd097          	auipc	ra,0xffffd
    800035c8:	60e080e7          	jalr	1550(ra) # 80000bd2 <acquire>
  b->refcnt--;
    800035cc:	40bc                	lw	a5,64(s1)
    800035ce:	37fd                	addw	a5,a5,-1
    800035d0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035d2:	00014517          	auipc	a0,0x14
    800035d6:	bd650513          	add	a0,a0,-1066 # 800171a8 <bcache>
    800035da:	ffffd097          	auipc	ra,0xffffd
    800035de:	6ac080e7          	jalr	1708(ra) # 80000c86 <release>
}
    800035e2:	60e2                	ld	ra,24(sp)
    800035e4:	6442                	ld	s0,16(sp)
    800035e6:	64a2                	ld	s1,8(sp)
    800035e8:	6105                	add	sp,sp,32
    800035ea:	8082                	ret

00000000800035ec <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800035ec:	1101                	add	sp,sp,-32
    800035ee:	ec06                	sd	ra,24(sp)
    800035f0:	e822                	sd	s0,16(sp)
    800035f2:	e426                	sd	s1,8(sp)
    800035f4:	e04a                	sd	s2,0(sp)
    800035f6:	1000                	add	s0,sp,32
    800035f8:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800035fa:	00d5d59b          	srlw	a1,a1,0xd
    800035fe:	0001c797          	auipc	a5,0x1c
    80003602:	2867a783          	lw	a5,646(a5) # 8001f884 <sb+0x1c>
    80003606:	9dbd                	addw	a1,a1,a5
    80003608:	00000097          	auipc	ra,0x0
    8000360c:	da0080e7          	jalr	-608(ra) # 800033a8 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003610:	0074f713          	and	a4,s1,7
    80003614:	4785                	li	a5,1
    80003616:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000361a:	14ce                	sll	s1,s1,0x33
    8000361c:	90d9                	srl	s1,s1,0x36
    8000361e:	00950733          	add	a4,a0,s1
    80003622:	05874703          	lbu	a4,88(a4)
    80003626:	00e7f6b3          	and	a3,a5,a4
    8000362a:	c69d                	beqz	a3,80003658 <bfree+0x6c>
    8000362c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000362e:	94aa                	add	s1,s1,a0
    80003630:	fff7c793          	not	a5,a5
    80003634:	8f7d                	and	a4,a4,a5
    80003636:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000363a:	00001097          	auipc	ra,0x1
    8000363e:	0f6080e7          	jalr	246(ra) # 80004730 <log_write>
  brelse(bp);
    80003642:	854a                	mv	a0,s2
    80003644:	00000097          	auipc	ra,0x0
    80003648:	e94080e7          	jalr	-364(ra) # 800034d8 <brelse>
}
    8000364c:	60e2                	ld	ra,24(sp)
    8000364e:	6442                	ld	s0,16(sp)
    80003650:	64a2                	ld	s1,8(sp)
    80003652:	6902                	ld	s2,0(sp)
    80003654:	6105                	add	sp,sp,32
    80003656:	8082                	ret
    panic("freeing free block");
    80003658:	00005517          	auipc	a0,0x5
    8000365c:	f0850513          	add	a0,a0,-248 # 80008560 <syscalls+0x100>
    80003660:	ffffd097          	auipc	ra,0xffffd
    80003664:	edc080e7          	jalr	-292(ra) # 8000053c <panic>

0000000080003668 <balloc>:
{
    80003668:	711d                	add	sp,sp,-96
    8000366a:	ec86                	sd	ra,88(sp)
    8000366c:	e8a2                	sd	s0,80(sp)
    8000366e:	e4a6                	sd	s1,72(sp)
    80003670:	e0ca                	sd	s2,64(sp)
    80003672:	fc4e                	sd	s3,56(sp)
    80003674:	f852                	sd	s4,48(sp)
    80003676:	f456                	sd	s5,40(sp)
    80003678:	f05a                	sd	s6,32(sp)
    8000367a:	ec5e                	sd	s7,24(sp)
    8000367c:	e862                	sd	s8,16(sp)
    8000367e:	e466                	sd	s9,8(sp)
    80003680:	1080                	add	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003682:	0001c797          	auipc	a5,0x1c
    80003686:	1ea7a783          	lw	a5,490(a5) # 8001f86c <sb+0x4>
    8000368a:	cff5                	beqz	a5,80003786 <balloc+0x11e>
    8000368c:	8baa                	mv	s7,a0
    8000368e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003690:	0001cb17          	auipc	s6,0x1c
    80003694:	1d8b0b13          	add	s6,s6,472 # 8001f868 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003698:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000369a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000369c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000369e:	6c89                	lui	s9,0x2
    800036a0:	a061                	j	80003728 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800036a2:	97ca                	add	a5,a5,s2
    800036a4:	8e55                	or	a2,a2,a3
    800036a6:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800036aa:	854a                	mv	a0,s2
    800036ac:	00001097          	auipc	ra,0x1
    800036b0:	084080e7          	jalr	132(ra) # 80004730 <log_write>
        brelse(bp);
    800036b4:	854a                	mv	a0,s2
    800036b6:	00000097          	auipc	ra,0x0
    800036ba:	e22080e7          	jalr	-478(ra) # 800034d8 <brelse>
  bp = bread(dev, bno);
    800036be:	85a6                	mv	a1,s1
    800036c0:	855e                	mv	a0,s7
    800036c2:	00000097          	auipc	ra,0x0
    800036c6:	ce6080e7          	jalr	-794(ra) # 800033a8 <bread>
    800036ca:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800036cc:	40000613          	li	a2,1024
    800036d0:	4581                	li	a1,0
    800036d2:	05850513          	add	a0,a0,88
    800036d6:	ffffd097          	auipc	ra,0xffffd
    800036da:	5f8080e7          	jalr	1528(ra) # 80000cce <memset>
  log_write(bp);
    800036de:	854a                	mv	a0,s2
    800036e0:	00001097          	auipc	ra,0x1
    800036e4:	050080e7          	jalr	80(ra) # 80004730 <log_write>
  brelse(bp);
    800036e8:	854a                	mv	a0,s2
    800036ea:	00000097          	auipc	ra,0x0
    800036ee:	dee080e7          	jalr	-530(ra) # 800034d8 <brelse>
}
    800036f2:	8526                	mv	a0,s1
    800036f4:	60e6                	ld	ra,88(sp)
    800036f6:	6446                	ld	s0,80(sp)
    800036f8:	64a6                	ld	s1,72(sp)
    800036fa:	6906                	ld	s2,64(sp)
    800036fc:	79e2                	ld	s3,56(sp)
    800036fe:	7a42                	ld	s4,48(sp)
    80003700:	7aa2                	ld	s5,40(sp)
    80003702:	7b02                	ld	s6,32(sp)
    80003704:	6be2                	ld	s7,24(sp)
    80003706:	6c42                	ld	s8,16(sp)
    80003708:	6ca2                	ld	s9,8(sp)
    8000370a:	6125                	add	sp,sp,96
    8000370c:	8082                	ret
    brelse(bp);
    8000370e:	854a                	mv	a0,s2
    80003710:	00000097          	auipc	ra,0x0
    80003714:	dc8080e7          	jalr	-568(ra) # 800034d8 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003718:	015c87bb          	addw	a5,s9,s5
    8000371c:	00078a9b          	sext.w	s5,a5
    80003720:	004b2703          	lw	a4,4(s6)
    80003724:	06eaf163          	bgeu	s5,a4,80003786 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003728:	41fad79b          	sraw	a5,s5,0x1f
    8000372c:	0137d79b          	srlw	a5,a5,0x13
    80003730:	015787bb          	addw	a5,a5,s5
    80003734:	40d7d79b          	sraw	a5,a5,0xd
    80003738:	01cb2583          	lw	a1,28(s6)
    8000373c:	9dbd                	addw	a1,a1,a5
    8000373e:	855e                	mv	a0,s7
    80003740:	00000097          	auipc	ra,0x0
    80003744:	c68080e7          	jalr	-920(ra) # 800033a8 <bread>
    80003748:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000374a:	004b2503          	lw	a0,4(s6)
    8000374e:	000a849b          	sext.w	s1,s5
    80003752:	8762                	mv	a4,s8
    80003754:	faa4fde3          	bgeu	s1,a0,8000370e <balloc+0xa6>
      m = 1 << (bi % 8);
    80003758:	00777693          	and	a3,a4,7
    8000375c:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003760:	41f7579b          	sraw	a5,a4,0x1f
    80003764:	01d7d79b          	srlw	a5,a5,0x1d
    80003768:	9fb9                	addw	a5,a5,a4
    8000376a:	4037d79b          	sraw	a5,a5,0x3
    8000376e:	00f90633          	add	a2,s2,a5
    80003772:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    80003776:	00c6f5b3          	and	a1,a3,a2
    8000377a:	d585                	beqz	a1,800036a2 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000377c:	2705                	addw	a4,a4,1
    8000377e:	2485                	addw	s1,s1,1
    80003780:	fd471ae3          	bne	a4,s4,80003754 <balloc+0xec>
    80003784:	b769                	j	8000370e <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003786:	00005517          	auipc	a0,0x5
    8000378a:	df250513          	add	a0,a0,-526 # 80008578 <syscalls+0x118>
    8000378e:	ffffd097          	auipc	ra,0xffffd
    80003792:	df8080e7          	jalr	-520(ra) # 80000586 <printf>
  return 0;
    80003796:	4481                	li	s1,0
    80003798:	bfa9                	j	800036f2 <balloc+0x8a>

000000008000379a <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000379a:	7179                	add	sp,sp,-48
    8000379c:	f406                	sd	ra,40(sp)
    8000379e:	f022                	sd	s0,32(sp)
    800037a0:	ec26                	sd	s1,24(sp)
    800037a2:	e84a                	sd	s2,16(sp)
    800037a4:	e44e                	sd	s3,8(sp)
    800037a6:	e052                	sd	s4,0(sp)
    800037a8:	1800                	add	s0,sp,48
    800037aa:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800037ac:	47ad                	li	a5,11
    800037ae:	02b7e863          	bltu	a5,a1,800037de <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800037b2:	02059793          	sll	a5,a1,0x20
    800037b6:	01e7d593          	srl	a1,a5,0x1e
    800037ba:	00b504b3          	add	s1,a0,a1
    800037be:	0504a903          	lw	s2,80(s1)
    800037c2:	06091e63          	bnez	s2,8000383e <bmap+0xa4>
      addr = balloc(ip->dev);
    800037c6:	4108                	lw	a0,0(a0)
    800037c8:	00000097          	auipc	ra,0x0
    800037cc:	ea0080e7          	jalr	-352(ra) # 80003668 <balloc>
    800037d0:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800037d4:	06090563          	beqz	s2,8000383e <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    800037d8:	0524a823          	sw	s2,80(s1)
    800037dc:	a08d                	j	8000383e <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800037de:	ff45849b          	addw	s1,a1,-12
    800037e2:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800037e6:	0ff00793          	li	a5,255
    800037ea:	08e7e563          	bltu	a5,a4,80003874 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800037ee:	08052903          	lw	s2,128(a0)
    800037f2:	00091d63          	bnez	s2,8000380c <bmap+0x72>
      addr = balloc(ip->dev);
    800037f6:	4108                	lw	a0,0(a0)
    800037f8:	00000097          	auipc	ra,0x0
    800037fc:	e70080e7          	jalr	-400(ra) # 80003668 <balloc>
    80003800:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003804:	02090d63          	beqz	s2,8000383e <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003808:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000380c:	85ca                	mv	a1,s2
    8000380e:	0009a503          	lw	a0,0(s3)
    80003812:	00000097          	auipc	ra,0x0
    80003816:	b96080e7          	jalr	-1130(ra) # 800033a8 <bread>
    8000381a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000381c:	05850793          	add	a5,a0,88
    if((addr = a[bn]) == 0){
    80003820:	02049713          	sll	a4,s1,0x20
    80003824:	01e75593          	srl	a1,a4,0x1e
    80003828:	00b784b3          	add	s1,a5,a1
    8000382c:	0004a903          	lw	s2,0(s1)
    80003830:	02090063          	beqz	s2,80003850 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003834:	8552                	mv	a0,s4
    80003836:	00000097          	auipc	ra,0x0
    8000383a:	ca2080e7          	jalr	-862(ra) # 800034d8 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000383e:	854a                	mv	a0,s2
    80003840:	70a2                	ld	ra,40(sp)
    80003842:	7402                	ld	s0,32(sp)
    80003844:	64e2                	ld	s1,24(sp)
    80003846:	6942                	ld	s2,16(sp)
    80003848:	69a2                	ld	s3,8(sp)
    8000384a:	6a02                	ld	s4,0(sp)
    8000384c:	6145                	add	sp,sp,48
    8000384e:	8082                	ret
      addr = balloc(ip->dev);
    80003850:	0009a503          	lw	a0,0(s3)
    80003854:	00000097          	auipc	ra,0x0
    80003858:	e14080e7          	jalr	-492(ra) # 80003668 <balloc>
    8000385c:	0005091b          	sext.w	s2,a0
      if(addr){
    80003860:	fc090ae3          	beqz	s2,80003834 <bmap+0x9a>
        a[bn] = addr;
    80003864:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003868:	8552                	mv	a0,s4
    8000386a:	00001097          	auipc	ra,0x1
    8000386e:	ec6080e7          	jalr	-314(ra) # 80004730 <log_write>
    80003872:	b7c9                	j	80003834 <bmap+0x9a>
  panic("bmap: out of range");
    80003874:	00005517          	auipc	a0,0x5
    80003878:	d1c50513          	add	a0,a0,-740 # 80008590 <syscalls+0x130>
    8000387c:	ffffd097          	auipc	ra,0xffffd
    80003880:	cc0080e7          	jalr	-832(ra) # 8000053c <panic>

0000000080003884 <iget>:
{
    80003884:	7179                	add	sp,sp,-48
    80003886:	f406                	sd	ra,40(sp)
    80003888:	f022                	sd	s0,32(sp)
    8000388a:	ec26                	sd	s1,24(sp)
    8000388c:	e84a                	sd	s2,16(sp)
    8000388e:	e44e                	sd	s3,8(sp)
    80003890:	e052                	sd	s4,0(sp)
    80003892:	1800                	add	s0,sp,48
    80003894:	89aa                	mv	s3,a0
    80003896:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003898:	0001c517          	auipc	a0,0x1c
    8000389c:	ff050513          	add	a0,a0,-16 # 8001f888 <itable>
    800038a0:	ffffd097          	auipc	ra,0xffffd
    800038a4:	332080e7          	jalr	818(ra) # 80000bd2 <acquire>
  empty = 0;
    800038a8:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800038aa:	0001c497          	auipc	s1,0x1c
    800038ae:	ff648493          	add	s1,s1,-10 # 8001f8a0 <itable+0x18>
    800038b2:	0001e697          	auipc	a3,0x1e
    800038b6:	a7e68693          	add	a3,a3,-1410 # 80021330 <log>
    800038ba:	a039                	j	800038c8 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038bc:	02090b63          	beqz	s2,800038f2 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800038c0:	08848493          	add	s1,s1,136
    800038c4:	02d48a63          	beq	s1,a3,800038f8 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800038c8:	449c                	lw	a5,8(s1)
    800038ca:	fef059e3          	blez	a5,800038bc <iget+0x38>
    800038ce:	4098                	lw	a4,0(s1)
    800038d0:	ff3716e3          	bne	a4,s3,800038bc <iget+0x38>
    800038d4:	40d8                	lw	a4,4(s1)
    800038d6:	ff4713e3          	bne	a4,s4,800038bc <iget+0x38>
      ip->ref++;
    800038da:	2785                	addw	a5,a5,1
    800038dc:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800038de:	0001c517          	auipc	a0,0x1c
    800038e2:	faa50513          	add	a0,a0,-86 # 8001f888 <itable>
    800038e6:	ffffd097          	auipc	ra,0xffffd
    800038ea:	3a0080e7          	jalr	928(ra) # 80000c86 <release>
      return ip;
    800038ee:	8926                	mv	s2,s1
    800038f0:	a03d                	j	8000391e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038f2:	f7f9                	bnez	a5,800038c0 <iget+0x3c>
    800038f4:	8926                	mv	s2,s1
    800038f6:	b7e9                	j	800038c0 <iget+0x3c>
  if(empty == 0)
    800038f8:	02090c63          	beqz	s2,80003930 <iget+0xac>
  ip->dev = dev;
    800038fc:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003900:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003904:	4785                	li	a5,1
    80003906:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000390a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000390e:	0001c517          	auipc	a0,0x1c
    80003912:	f7a50513          	add	a0,a0,-134 # 8001f888 <itable>
    80003916:	ffffd097          	auipc	ra,0xffffd
    8000391a:	370080e7          	jalr	880(ra) # 80000c86 <release>
}
    8000391e:	854a                	mv	a0,s2
    80003920:	70a2                	ld	ra,40(sp)
    80003922:	7402                	ld	s0,32(sp)
    80003924:	64e2                	ld	s1,24(sp)
    80003926:	6942                	ld	s2,16(sp)
    80003928:	69a2                	ld	s3,8(sp)
    8000392a:	6a02                	ld	s4,0(sp)
    8000392c:	6145                	add	sp,sp,48
    8000392e:	8082                	ret
    panic("iget: no inodes");
    80003930:	00005517          	auipc	a0,0x5
    80003934:	c7850513          	add	a0,a0,-904 # 800085a8 <syscalls+0x148>
    80003938:	ffffd097          	auipc	ra,0xffffd
    8000393c:	c04080e7          	jalr	-1020(ra) # 8000053c <panic>

0000000080003940 <fsinit>:
fsinit(int dev) {
    80003940:	7179                	add	sp,sp,-48
    80003942:	f406                	sd	ra,40(sp)
    80003944:	f022                	sd	s0,32(sp)
    80003946:	ec26                	sd	s1,24(sp)
    80003948:	e84a                	sd	s2,16(sp)
    8000394a:	e44e                	sd	s3,8(sp)
    8000394c:	1800                	add	s0,sp,48
    8000394e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003950:	4585                	li	a1,1
    80003952:	00000097          	auipc	ra,0x0
    80003956:	a56080e7          	jalr	-1450(ra) # 800033a8 <bread>
    8000395a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000395c:	0001c997          	auipc	s3,0x1c
    80003960:	f0c98993          	add	s3,s3,-244 # 8001f868 <sb>
    80003964:	02000613          	li	a2,32
    80003968:	05850593          	add	a1,a0,88
    8000396c:	854e                	mv	a0,s3
    8000396e:	ffffd097          	auipc	ra,0xffffd
    80003972:	3bc080e7          	jalr	956(ra) # 80000d2a <memmove>
  brelse(bp);
    80003976:	8526                	mv	a0,s1
    80003978:	00000097          	auipc	ra,0x0
    8000397c:	b60080e7          	jalr	-1184(ra) # 800034d8 <brelse>
  if(sb.magic != FSMAGIC)
    80003980:	0009a703          	lw	a4,0(s3)
    80003984:	102037b7          	lui	a5,0x10203
    80003988:	04078793          	add	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000398c:	02f71263          	bne	a4,a5,800039b0 <fsinit+0x70>
  initlog(dev, &sb);
    80003990:	0001c597          	auipc	a1,0x1c
    80003994:	ed858593          	add	a1,a1,-296 # 8001f868 <sb>
    80003998:	854a                	mv	a0,s2
    8000399a:	00001097          	auipc	ra,0x1
    8000399e:	b2c080e7          	jalr	-1236(ra) # 800044c6 <initlog>
}
    800039a2:	70a2                	ld	ra,40(sp)
    800039a4:	7402                	ld	s0,32(sp)
    800039a6:	64e2                	ld	s1,24(sp)
    800039a8:	6942                	ld	s2,16(sp)
    800039aa:	69a2                	ld	s3,8(sp)
    800039ac:	6145                	add	sp,sp,48
    800039ae:	8082                	ret
    panic("invalid file system");
    800039b0:	00005517          	auipc	a0,0x5
    800039b4:	c0850513          	add	a0,a0,-1016 # 800085b8 <syscalls+0x158>
    800039b8:	ffffd097          	auipc	ra,0xffffd
    800039bc:	b84080e7          	jalr	-1148(ra) # 8000053c <panic>

00000000800039c0 <iinit>:
{
    800039c0:	7179                	add	sp,sp,-48
    800039c2:	f406                	sd	ra,40(sp)
    800039c4:	f022                	sd	s0,32(sp)
    800039c6:	ec26                	sd	s1,24(sp)
    800039c8:	e84a                	sd	s2,16(sp)
    800039ca:	e44e                	sd	s3,8(sp)
    800039cc:	1800                	add	s0,sp,48
  initlock(&itable.lock, "itable");
    800039ce:	00005597          	auipc	a1,0x5
    800039d2:	c0258593          	add	a1,a1,-1022 # 800085d0 <syscalls+0x170>
    800039d6:	0001c517          	auipc	a0,0x1c
    800039da:	eb250513          	add	a0,a0,-334 # 8001f888 <itable>
    800039de:	ffffd097          	auipc	ra,0xffffd
    800039e2:	164080e7          	jalr	356(ra) # 80000b42 <initlock>
  for(i = 0; i < NINODE; i++) {
    800039e6:	0001c497          	auipc	s1,0x1c
    800039ea:	eca48493          	add	s1,s1,-310 # 8001f8b0 <itable+0x28>
    800039ee:	0001e997          	auipc	s3,0x1e
    800039f2:	95298993          	add	s3,s3,-1710 # 80021340 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800039f6:	00005917          	auipc	s2,0x5
    800039fa:	be290913          	add	s2,s2,-1054 # 800085d8 <syscalls+0x178>
    800039fe:	85ca                	mv	a1,s2
    80003a00:	8526                	mv	a0,s1
    80003a02:	00001097          	auipc	ra,0x1
    80003a06:	e12080e7          	jalr	-494(ra) # 80004814 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003a0a:	08848493          	add	s1,s1,136
    80003a0e:	ff3498e3          	bne	s1,s3,800039fe <iinit+0x3e>
}
    80003a12:	70a2                	ld	ra,40(sp)
    80003a14:	7402                	ld	s0,32(sp)
    80003a16:	64e2                	ld	s1,24(sp)
    80003a18:	6942                	ld	s2,16(sp)
    80003a1a:	69a2                	ld	s3,8(sp)
    80003a1c:	6145                	add	sp,sp,48
    80003a1e:	8082                	ret

0000000080003a20 <ialloc>:
{
    80003a20:	7139                	add	sp,sp,-64
    80003a22:	fc06                	sd	ra,56(sp)
    80003a24:	f822                	sd	s0,48(sp)
    80003a26:	f426                	sd	s1,40(sp)
    80003a28:	f04a                	sd	s2,32(sp)
    80003a2a:	ec4e                	sd	s3,24(sp)
    80003a2c:	e852                	sd	s4,16(sp)
    80003a2e:	e456                	sd	s5,8(sp)
    80003a30:	e05a                	sd	s6,0(sp)
    80003a32:	0080                	add	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a34:	0001c717          	auipc	a4,0x1c
    80003a38:	e4072703          	lw	a4,-448(a4) # 8001f874 <sb+0xc>
    80003a3c:	4785                	li	a5,1
    80003a3e:	04e7f863          	bgeu	a5,a4,80003a8e <ialloc+0x6e>
    80003a42:	8aaa                	mv	s5,a0
    80003a44:	8b2e                	mv	s6,a1
    80003a46:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003a48:	0001ca17          	auipc	s4,0x1c
    80003a4c:	e20a0a13          	add	s4,s4,-480 # 8001f868 <sb>
    80003a50:	00495593          	srl	a1,s2,0x4
    80003a54:	018a2783          	lw	a5,24(s4)
    80003a58:	9dbd                	addw	a1,a1,a5
    80003a5a:	8556                	mv	a0,s5
    80003a5c:	00000097          	auipc	ra,0x0
    80003a60:	94c080e7          	jalr	-1716(ra) # 800033a8 <bread>
    80003a64:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003a66:	05850993          	add	s3,a0,88
    80003a6a:	00f97793          	and	a5,s2,15
    80003a6e:	079a                	sll	a5,a5,0x6
    80003a70:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003a72:	00099783          	lh	a5,0(s3)
    80003a76:	cf9d                	beqz	a5,80003ab4 <ialloc+0x94>
    brelse(bp);
    80003a78:	00000097          	auipc	ra,0x0
    80003a7c:	a60080e7          	jalr	-1440(ra) # 800034d8 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a80:	0905                	add	s2,s2,1
    80003a82:	00ca2703          	lw	a4,12(s4)
    80003a86:	0009079b          	sext.w	a5,s2
    80003a8a:	fce7e3e3          	bltu	a5,a4,80003a50 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80003a8e:	00005517          	auipc	a0,0x5
    80003a92:	b5250513          	add	a0,a0,-1198 # 800085e0 <syscalls+0x180>
    80003a96:	ffffd097          	auipc	ra,0xffffd
    80003a9a:	af0080e7          	jalr	-1296(ra) # 80000586 <printf>
  return 0;
    80003a9e:	4501                	li	a0,0
}
    80003aa0:	70e2                	ld	ra,56(sp)
    80003aa2:	7442                	ld	s0,48(sp)
    80003aa4:	74a2                	ld	s1,40(sp)
    80003aa6:	7902                	ld	s2,32(sp)
    80003aa8:	69e2                	ld	s3,24(sp)
    80003aaa:	6a42                	ld	s4,16(sp)
    80003aac:	6aa2                	ld	s5,8(sp)
    80003aae:	6b02                	ld	s6,0(sp)
    80003ab0:	6121                	add	sp,sp,64
    80003ab2:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003ab4:	04000613          	li	a2,64
    80003ab8:	4581                	li	a1,0
    80003aba:	854e                	mv	a0,s3
    80003abc:	ffffd097          	auipc	ra,0xffffd
    80003ac0:	212080e7          	jalr	530(ra) # 80000cce <memset>
      dip->type = type;
    80003ac4:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003ac8:	8526                	mv	a0,s1
    80003aca:	00001097          	auipc	ra,0x1
    80003ace:	c66080e7          	jalr	-922(ra) # 80004730 <log_write>
      brelse(bp);
    80003ad2:	8526                	mv	a0,s1
    80003ad4:	00000097          	auipc	ra,0x0
    80003ad8:	a04080e7          	jalr	-1532(ra) # 800034d8 <brelse>
      return iget(dev, inum);
    80003adc:	0009059b          	sext.w	a1,s2
    80003ae0:	8556                	mv	a0,s5
    80003ae2:	00000097          	auipc	ra,0x0
    80003ae6:	da2080e7          	jalr	-606(ra) # 80003884 <iget>
    80003aea:	bf5d                	j	80003aa0 <ialloc+0x80>

0000000080003aec <iupdate>:
{
    80003aec:	1101                	add	sp,sp,-32
    80003aee:	ec06                	sd	ra,24(sp)
    80003af0:	e822                	sd	s0,16(sp)
    80003af2:	e426                	sd	s1,8(sp)
    80003af4:	e04a                	sd	s2,0(sp)
    80003af6:	1000                	add	s0,sp,32
    80003af8:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003afa:	415c                	lw	a5,4(a0)
    80003afc:	0047d79b          	srlw	a5,a5,0x4
    80003b00:	0001c597          	auipc	a1,0x1c
    80003b04:	d805a583          	lw	a1,-640(a1) # 8001f880 <sb+0x18>
    80003b08:	9dbd                	addw	a1,a1,a5
    80003b0a:	4108                	lw	a0,0(a0)
    80003b0c:	00000097          	auipc	ra,0x0
    80003b10:	89c080e7          	jalr	-1892(ra) # 800033a8 <bread>
    80003b14:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b16:	05850793          	add	a5,a0,88
    80003b1a:	40d8                	lw	a4,4(s1)
    80003b1c:	8b3d                	and	a4,a4,15
    80003b1e:	071a                	sll	a4,a4,0x6
    80003b20:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003b22:	04449703          	lh	a4,68(s1)
    80003b26:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003b2a:	04649703          	lh	a4,70(s1)
    80003b2e:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003b32:	04849703          	lh	a4,72(s1)
    80003b36:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003b3a:	04a49703          	lh	a4,74(s1)
    80003b3e:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003b42:	44f8                	lw	a4,76(s1)
    80003b44:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003b46:	03400613          	li	a2,52
    80003b4a:	05048593          	add	a1,s1,80
    80003b4e:	00c78513          	add	a0,a5,12
    80003b52:	ffffd097          	auipc	ra,0xffffd
    80003b56:	1d8080e7          	jalr	472(ra) # 80000d2a <memmove>
  log_write(bp);
    80003b5a:	854a                	mv	a0,s2
    80003b5c:	00001097          	auipc	ra,0x1
    80003b60:	bd4080e7          	jalr	-1068(ra) # 80004730 <log_write>
  brelse(bp);
    80003b64:	854a                	mv	a0,s2
    80003b66:	00000097          	auipc	ra,0x0
    80003b6a:	972080e7          	jalr	-1678(ra) # 800034d8 <brelse>
}
    80003b6e:	60e2                	ld	ra,24(sp)
    80003b70:	6442                	ld	s0,16(sp)
    80003b72:	64a2                	ld	s1,8(sp)
    80003b74:	6902                	ld	s2,0(sp)
    80003b76:	6105                	add	sp,sp,32
    80003b78:	8082                	ret

0000000080003b7a <idup>:
{
    80003b7a:	1101                	add	sp,sp,-32
    80003b7c:	ec06                	sd	ra,24(sp)
    80003b7e:	e822                	sd	s0,16(sp)
    80003b80:	e426                	sd	s1,8(sp)
    80003b82:	1000                	add	s0,sp,32
    80003b84:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b86:	0001c517          	auipc	a0,0x1c
    80003b8a:	d0250513          	add	a0,a0,-766 # 8001f888 <itable>
    80003b8e:	ffffd097          	auipc	ra,0xffffd
    80003b92:	044080e7          	jalr	68(ra) # 80000bd2 <acquire>
  ip->ref++;
    80003b96:	449c                	lw	a5,8(s1)
    80003b98:	2785                	addw	a5,a5,1
    80003b9a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b9c:	0001c517          	auipc	a0,0x1c
    80003ba0:	cec50513          	add	a0,a0,-788 # 8001f888 <itable>
    80003ba4:	ffffd097          	auipc	ra,0xffffd
    80003ba8:	0e2080e7          	jalr	226(ra) # 80000c86 <release>
}
    80003bac:	8526                	mv	a0,s1
    80003bae:	60e2                	ld	ra,24(sp)
    80003bb0:	6442                	ld	s0,16(sp)
    80003bb2:	64a2                	ld	s1,8(sp)
    80003bb4:	6105                	add	sp,sp,32
    80003bb6:	8082                	ret

0000000080003bb8 <ilock>:
{
    80003bb8:	1101                	add	sp,sp,-32
    80003bba:	ec06                	sd	ra,24(sp)
    80003bbc:	e822                	sd	s0,16(sp)
    80003bbe:	e426                	sd	s1,8(sp)
    80003bc0:	e04a                	sd	s2,0(sp)
    80003bc2:	1000                	add	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003bc4:	c115                	beqz	a0,80003be8 <ilock+0x30>
    80003bc6:	84aa                	mv	s1,a0
    80003bc8:	451c                	lw	a5,8(a0)
    80003bca:	00f05f63          	blez	a5,80003be8 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003bce:	0541                	add	a0,a0,16
    80003bd0:	00001097          	auipc	ra,0x1
    80003bd4:	c7e080e7          	jalr	-898(ra) # 8000484e <acquiresleep>
  if(ip->valid == 0){
    80003bd8:	40bc                	lw	a5,64(s1)
    80003bda:	cf99                	beqz	a5,80003bf8 <ilock+0x40>
}
    80003bdc:	60e2                	ld	ra,24(sp)
    80003bde:	6442                	ld	s0,16(sp)
    80003be0:	64a2                	ld	s1,8(sp)
    80003be2:	6902                	ld	s2,0(sp)
    80003be4:	6105                	add	sp,sp,32
    80003be6:	8082                	ret
    panic("ilock");
    80003be8:	00005517          	auipc	a0,0x5
    80003bec:	a1050513          	add	a0,a0,-1520 # 800085f8 <syscalls+0x198>
    80003bf0:	ffffd097          	auipc	ra,0xffffd
    80003bf4:	94c080e7          	jalr	-1716(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003bf8:	40dc                	lw	a5,4(s1)
    80003bfa:	0047d79b          	srlw	a5,a5,0x4
    80003bfe:	0001c597          	auipc	a1,0x1c
    80003c02:	c825a583          	lw	a1,-894(a1) # 8001f880 <sb+0x18>
    80003c06:	9dbd                	addw	a1,a1,a5
    80003c08:	4088                	lw	a0,0(s1)
    80003c0a:	fffff097          	auipc	ra,0xfffff
    80003c0e:	79e080e7          	jalr	1950(ra) # 800033a8 <bread>
    80003c12:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c14:	05850593          	add	a1,a0,88
    80003c18:	40dc                	lw	a5,4(s1)
    80003c1a:	8bbd                	and	a5,a5,15
    80003c1c:	079a                	sll	a5,a5,0x6
    80003c1e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003c20:	00059783          	lh	a5,0(a1)
    80003c24:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003c28:	00259783          	lh	a5,2(a1)
    80003c2c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003c30:	00459783          	lh	a5,4(a1)
    80003c34:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003c38:	00659783          	lh	a5,6(a1)
    80003c3c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003c40:	459c                	lw	a5,8(a1)
    80003c42:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003c44:	03400613          	li	a2,52
    80003c48:	05b1                	add	a1,a1,12
    80003c4a:	05048513          	add	a0,s1,80
    80003c4e:	ffffd097          	auipc	ra,0xffffd
    80003c52:	0dc080e7          	jalr	220(ra) # 80000d2a <memmove>
    brelse(bp);
    80003c56:	854a                	mv	a0,s2
    80003c58:	00000097          	auipc	ra,0x0
    80003c5c:	880080e7          	jalr	-1920(ra) # 800034d8 <brelse>
    ip->valid = 1;
    80003c60:	4785                	li	a5,1
    80003c62:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003c64:	04449783          	lh	a5,68(s1)
    80003c68:	fbb5                	bnez	a5,80003bdc <ilock+0x24>
      panic("ilock: no type");
    80003c6a:	00005517          	auipc	a0,0x5
    80003c6e:	99650513          	add	a0,a0,-1642 # 80008600 <syscalls+0x1a0>
    80003c72:	ffffd097          	auipc	ra,0xffffd
    80003c76:	8ca080e7          	jalr	-1846(ra) # 8000053c <panic>

0000000080003c7a <iunlock>:
{
    80003c7a:	1101                	add	sp,sp,-32
    80003c7c:	ec06                	sd	ra,24(sp)
    80003c7e:	e822                	sd	s0,16(sp)
    80003c80:	e426                	sd	s1,8(sp)
    80003c82:	e04a                	sd	s2,0(sp)
    80003c84:	1000                	add	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003c86:	c905                	beqz	a0,80003cb6 <iunlock+0x3c>
    80003c88:	84aa                	mv	s1,a0
    80003c8a:	01050913          	add	s2,a0,16
    80003c8e:	854a                	mv	a0,s2
    80003c90:	00001097          	auipc	ra,0x1
    80003c94:	c58080e7          	jalr	-936(ra) # 800048e8 <holdingsleep>
    80003c98:	cd19                	beqz	a0,80003cb6 <iunlock+0x3c>
    80003c9a:	449c                	lw	a5,8(s1)
    80003c9c:	00f05d63          	blez	a5,80003cb6 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003ca0:	854a                	mv	a0,s2
    80003ca2:	00001097          	auipc	ra,0x1
    80003ca6:	c02080e7          	jalr	-1022(ra) # 800048a4 <releasesleep>
}
    80003caa:	60e2                	ld	ra,24(sp)
    80003cac:	6442                	ld	s0,16(sp)
    80003cae:	64a2                	ld	s1,8(sp)
    80003cb0:	6902                	ld	s2,0(sp)
    80003cb2:	6105                	add	sp,sp,32
    80003cb4:	8082                	ret
    panic("iunlock");
    80003cb6:	00005517          	auipc	a0,0x5
    80003cba:	95a50513          	add	a0,a0,-1702 # 80008610 <syscalls+0x1b0>
    80003cbe:	ffffd097          	auipc	ra,0xffffd
    80003cc2:	87e080e7          	jalr	-1922(ra) # 8000053c <panic>

0000000080003cc6 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003cc6:	7179                	add	sp,sp,-48
    80003cc8:	f406                	sd	ra,40(sp)
    80003cca:	f022                	sd	s0,32(sp)
    80003ccc:	ec26                	sd	s1,24(sp)
    80003cce:	e84a                	sd	s2,16(sp)
    80003cd0:	e44e                	sd	s3,8(sp)
    80003cd2:	e052                	sd	s4,0(sp)
    80003cd4:	1800                	add	s0,sp,48
    80003cd6:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003cd8:	05050493          	add	s1,a0,80
    80003cdc:	08050913          	add	s2,a0,128
    80003ce0:	a021                	j	80003ce8 <itrunc+0x22>
    80003ce2:	0491                	add	s1,s1,4
    80003ce4:	01248d63          	beq	s1,s2,80003cfe <itrunc+0x38>
    if(ip->addrs[i]){
    80003ce8:	408c                	lw	a1,0(s1)
    80003cea:	dde5                	beqz	a1,80003ce2 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003cec:	0009a503          	lw	a0,0(s3)
    80003cf0:	00000097          	auipc	ra,0x0
    80003cf4:	8fc080e7          	jalr	-1796(ra) # 800035ec <bfree>
      ip->addrs[i] = 0;
    80003cf8:	0004a023          	sw	zero,0(s1)
    80003cfc:	b7dd                	j	80003ce2 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003cfe:	0809a583          	lw	a1,128(s3)
    80003d02:	e185                	bnez	a1,80003d22 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003d04:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003d08:	854e                	mv	a0,s3
    80003d0a:	00000097          	auipc	ra,0x0
    80003d0e:	de2080e7          	jalr	-542(ra) # 80003aec <iupdate>
}
    80003d12:	70a2                	ld	ra,40(sp)
    80003d14:	7402                	ld	s0,32(sp)
    80003d16:	64e2                	ld	s1,24(sp)
    80003d18:	6942                	ld	s2,16(sp)
    80003d1a:	69a2                	ld	s3,8(sp)
    80003d1c:	6a02                	ld	s4,0(sp)
    80003d1e:	6145                	add	sp,sp,48
    80003d20:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003d22:	0009a503          	lw	a0,0(s3)
    80003d26:	fffff097          	auipc	ra,0xfffff
    80003d2a:	682080e7          	jalr	1666(ra) # 800033a8 <bread>
    80003d2e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003d30:	05850493          	add	s1,a0,88
    80003d34:	45850913          	add	s2,a0,1112
    80003d38:	a021                	j	80003d40 <itrunc+0x7a>
    80003d3a:	0491                	add	s1,s1,4
    80003d3c:	01248b63          	beq	s1,s2,80003d52 <itrunc+0x8c>
      if(a[j])
    80003d40:	408c                	lw	a1,0(s1)
    80003d42:	dde5                	beqz	a1,80003d3a <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003d44:	0009a503          	lw	a0,0(s3)
    80003d48:	00000097          	auipc	ra,0x0
    80003d4c:	8a4080e7          	jalr	-1884(ra) # 800035ec <bfree>
    80003d50:	b7ed                	j	80003d3a <itrunc+0x74>
    brelse(bp);
    80003d52:	8552                	mv	a0,s4
    80003d54:	fffff097          	auipc	ra,0xfffff
    80003d58:	784080e7          	jalr	1924(ra) # 800034d8 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003d5c:	0809a583          	lw	a1,128(s3)
    80003d60:	0009a503          	lw	a0,0(s3)
    80003d64:	00000097          	auipc	ra,0x0
    80003d68:	888080e7          	jalr	-1912(ra) # 800035ec <bfree>
    ip->addrs[NDIRECT] = 0;
    80003d6c:	0809a023          	sw	zero,128(s3)
    80003d70:	bf51                	j	80003d04 <itrunc+0x3e>

0000000080003d72 <iput>:
{
    80003d72:	1101                	add	sp,sp,-32
    80003d74:	ec06                	sd	ra,24(sp)
    80003d76:	e822                	sd	s0,16(sp)
    80003d78:	e426                	sd	s1,8(sp)
    80003d7a:	e04a                	sd	s2,0(sp)
    80003d7c:	1000                	add	s0,sp,32
    80003d7e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d80:	0001c517          	auipc	a0,0x1c
    80003d84:	b0850513          	add	a0,a0,-1272 # 8001f888 <itable>
    80003d88:	ffffd097          	auipc	ra,0xffffd
    80003d8c:	e4a080e7          	jalr	-438(ra) # 80000bd2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d90:	4498                	lw	a4,8(s1)
    80003d92:	4785                	li	a5,1
    80003d94:	02f70363          	beq	a4,a5,80003dba <iput+0x48>
  ip->ref--;
    80003d98:	449c                	lw	a5,8(s1)
    80003d9a:	37fd                	addw	a5,a5,-1
    80003d9c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d9e:	0001c517          	auipc	a0,0x1c
    80003da2:	aea50513          	add	a0,a0,-1302 # 8001f888 <itable>
    80003da6:	ffffd097          	auipc	ra,0xffffd
    80003daa:	ee0080e7          	jalr	-288(ra) # 80000c86 <release>
}
    80003dae:	60e2                	ld	ra,24(sp)
    80003db0:	6442                	ld	s0,16(sp)
    80003db2:	64a2                	ld	s1,8(sp)
    80003db4:	6902                	ld	s2,0(sp)
    80003db6:	6105                	add	sp,sp,32
    80003db8:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003dba:	40bc                	lw	a5,64(s1)
    80003dbc:	dff1                	beqz	a5,80003d98 <iput+0x26>
    80003dbe:	04a49783          	lh	a5,74(s1)
    80003dc2:	fbf9                	bnez	a5,80003d98 <iput+0x26>
    acquiresleep(&ip->lock);
    80003dc4:	01048913          	add	s2,s1,16
    80003dc8:	854a                	mv	a0,s2
    80003dca:	00001097          	auipc	ra,0x1
    80003dce:	a84080e7          	jalr	-1404(ra) # 8000484e <acquiresleep>
    release(&itable.lock);
    80003dd2:	0001c517          	auipc	a0,0x1c
    80003dd6:	ab650513          	add	a0,a0,-1354 # 8001f888 <itable>
    80003dda:	ffffd097          	auipc	ra,0xffffd
    80003dde:	eac080e7          	jalr	-340(ra) # 80000c86 <release>
    itrunc(ip);
    80003de2:	8526                	mv	a0,s1
    80003de4:	00000097          	auipc	ra,0x0
    80003de8:	ee2080e7          	jalr	-286(ra) # 80003cc6 <itrunc>
    ip->type = 0;
    80003dec:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003df0:	8526                	mv	a0,s1
    80003df2:	00000097          	auipc	ra,0x0
    80003df6:	cfa080e7          	jalr	-774(ra) # 80003aec <iupdate>
    ip->valid = 0;
    80003dfa:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003dfe:	854a                	mv	a0,s2
    80003e00:	00001097          	auipc	ra,0x1
    80003e04:	aa4080e7          	jalr	-1372(ra) # 800048a4 <releasesleep>
    acquire(&itable.lock);
    80003e08:	0001c517          	auipc	a0,0x1c
    80003e0c:	a8050513          	add	a0,a0,-1408 # 8001f888 <itable>
    80003e10:	ffffd097          	auipc	ra,0xffffd
    80003e14:	dc2080e7          	jalr	-574(ra) # 80000bd2 <acquire>
    80003e18:	b741                	j	80003d98 <iput+0x26>

0000000080003e1a <iunlockput>:
{
    80003e1a:	1101                	add	sp,sp,-32
    80003e1c:	ec06                	sd	ra,24(sp)
    80003e1e:	e822                	sd	s0,16(sp)
    80003e20:	e426                	sd	s1,8(sp)
    80003e22:	1000                	add	s0,sp,32
    80003e24:	84aa                	mv	s1,a0
  iunlock(ip);
    80003e26:	00000097          	auipc	ra,0x0
    80003e2a:	e54080e7          	jalr	-428(ra) # 80003c7a <iunlock>
  iput(ip);
    80003e2e:	8526                	mv	a0,s1
    80003e30:	00000097          	auipc	ra,0x0
    80003e34:	f42080e7          	jalr	-190(ra) # 80003d72 <iput>
}
    80003e38:	60e2                	ld	ra,24(sp)
    80003e3a:	6442                	ld	s0,16(sp)
    80003e3c:	64a2                	ld	s1,8(sp)
    80003e3e:	6105                	add	sp,sp,32
    80003e40:	8082                	ret

0000000080003e42 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003e42:	1141                	add	sp,sp,-16
    80003e44:	e422                	sd	s0,8(sp)
    80003e46:	0800                	add	s0,sp,16
  st->dev = ip->dev;
    80003e48:	411c                	lw	a5,0(a0)
    80003e4a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003e4c:	415c                	lw	a5,4(a0)
    80003e4e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003e50:	04451783          	lh	a5,68(a0)
    80003e54:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e58:	04a51783          	lh	a5,74(a0)
    80003e5c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003e60:	04c56783          	lwu	a5,76(a0)
    80003e64:	e99c                	sd	a5,16(a1)
}
    80003e66:	6422                	ld	s0,8(sp)
    80003e68:	0141                	add	sp,sp,16
    80003e6a:	8082                	ret

0000000080003e6c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e6c:	457c                	lw	a5,76(a0)
    80003e6e:	0ed7e963          	bltu	a5,a3,80003f60 <readi+0xf4>
{
    80003e72:	7159                	add	sp,sp,-112
    80003e74:	f486                	sd	ra,104(sp)
    80003e76:	f0a2                	sd	s0,96(sp)
    80003e78:	eca6                	sd	s1,88(sp)
    80003e7a:	e8ca                	sd	s2,80(sp)
    80003e7c:	e4ce                	sd	s3,72(sp)
    80003e7e:	e0d2                	sd	s4,64(sp)
    80003e80:	fc56                	sd	s5,56(sp)
    80003e82:	f85a                	sd	s6,48(sp)
    80003e84:	f45e                	sd	s7,40(sp)
    80003e86:	f062                	sd	s8,32(sp)
    80003e88:	ec66                	sd	s9,24(sp)
    80003e8a:	e86a                	sd	s10,16(sp)
    80003e8c:	e46e                	sd	s11,8(sp)
    80003e8e:	1880                	add	s0,sp,112
    80003e90:	8b2a                	mv	s6,a0
    80003e92:	8bae                	mv	s7,a1
    80003e94:	8a32                	mv	s4,a2
    80003e96:	84b6                	mv	s1,a3
    80003e98:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003e9a:	9f35                	addw	a4,a4,a3
    return 0;
    80003e9c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003e9e:	0ad76063          	bltu	a4,a3,80003f3e <readi+0xd2>
  if(off + n > ip->size)
    80003ea2:	00e7f463          	bgeu	a5,a4,80003eaa <readi+0x3e>
    n = ip->size - off;
    80003ea6:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003eaa:	0a0a8963          	beqz	s5,80003f5c <readi+0xf0>
    80003eae:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003eb0:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003eb4:	5c7d                	li	s8,-1
    80003eb6:	a82d                	j	80003ef0 <readi+0x84>
    80003eb8:	020d1d93          	sll	s11,s10,0x20
    80003ebc:	020ddd93          	srl	s11,s11,0x20
    80003ec0:	05890613          	add	a2,s2,88
    80003ec4:	86ee                	mv	a3,s11
    80003ec6:	963a                	add	a2,a2,a4
    80003ec8:	85d2                	mv	a1,s4
    80003eca:	855e                	mv	a0,s7
    80003ecc:	ffffe097          	auipc	ra,0xffffe
    80003ed0:	79a080e7          	jalr	1946(ra) # 80002666 <either_copyout>
    80003ed4:	05850d63          	beq	a0,s8,80003f2e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ed8:	854a                	mv	a0,s2
    80003eda:	fffff097          	auipc	ra,0xfffff
    80003ede:	5fe080e7          	jalr	1534(ra) # 800034d8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ee2:	013d09bb          	addw	s3,s10,s3
    80003ee6:	009d04bb          	addw	s1,s10,s1
    80003eea:	9a6e                	add	s4,s4,s11
    80003eec:	0559f763          	bgeu	s3,s5,80003f3a <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003ef0:	00a4d59b          	srlw	a1,s1,0xa
    80003ef4:	855a                	mv	a0,s6
    80003ef6:	00000097          	auipc	ra,0x0
    80003efa:	8a4080e7          	jalr	-1884(ra) # 8000379a <bmap>
    80003efe:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003f02:	cd85                	beqz	a1,80003f3a <readi+0xce>
    bp = bread(ip->dev, addr);
    80003f04:	000b2503          	lw	a0,0(s6)
    80003f08:	fffff097          	auipc	ra,0xfffff
    80003f0c:	4a0080e7          	jalr	1184(ra) # 800033a8 <bread>
    80003f10:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f12:	3ff4f713          	and	a4,s1,1023
    80003f16:	40ec87bb          	subw	a5,s9,a4
    80003f1a:	413a86bb          	subw	a3,s5,s3
    80003f1e:	8d3e                	mv	s10,a5
    80003f20:	2781                	sext.w	a5,a5
    80003f22:	0006861b          	sext.w	a2,a3
    80003f26:	f8f679e3          	bgeu	a2,a5,80003eb8 <readi+0x4c>
    80003f2a:	8d36                	mv	s10,a3
    80003f2c:	b771                	j	80003eb8 <readi+0x4c>
      brelse(bp);
    80003f2e:	854a                	mv	a0,s2
    80003f30:	fffff097          	auipc	ra,0xfffff
    80003f34:	5a8080e7          	jalr	1448(ra) # 800034d8 <brelse>
      tot = -1;
    80003f38:	59fd                	li	s3,-1
  }
  return tot;
    80003f3a:	0009851b          	sext.w	a0,s3
}
    80003f3e:	70a6                	ld	ra,104(sp)
    80003f40:	7406                	ld	s0,96(sp)
    80003f42:	64e6                	ld	s1,88(sp)
    80003f44:	6946                	ld	s2,80(sp)
    80003f46:	69a6                	ld	s3,72(sp)
    80003f48:	6a06                	ld	s4,64(sp)
    80003f4a:	7ae2                	ld	s5,56(sp)
    80003f4c:	7b42                	ld	s6,48(sp)
    80003f4e:	7ba2                	ld	s7,40(sp)
    80003f50:	7c02                	ld	s8,32(sp)
    80003f52:	6ce2                	ld	s9,24(sp)
    80003f54:	6d42                	ld	s10,16(sp)
    80003f56:	6da2                	ld	s11,8(sp)
    80003f58:	6165                	add	sp,sp,112
    80003f5a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f5c:	89d6                	mv	s3,s5
    80003f5e:	bff1                	j	80003f3a <readi+0xce>
    return 0;
    80003f60:	4501                	li	a0,0
}
    80003f62:	8082                	ret

0000000080003f64 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f64:	457c                	lw	a5,76(a0)
    80003f66:	10d7e863          	bltu	a5,a3,80004076 <writei+0x112>
{
    80003f6a:	7159                	add	sp,sp,-112
    80003f6c:	f486                	sd	ra,104(sp)
    80003f6e:	f0a2                	sd	s0,96(sp)
    80003f70:	eca6                	sd	s1,88(sp)
    80003f72:	e8ca                	sd	s2,80(sp)
    80003f74:	e4ce                	sd	s3,72(sp)
    80003f76:	e0d2                	sd	s4,64(sp)
    80003f78:	fc56                	sd	s5,56(sp)
    80003f7a:	f85a                	sd	s6,48(sp)
    80003f7c:	f45e                	sd	s7,40(sp)
    80003f7e:	f062                	sd	s8,32(sp)
    80003f80:	ec66                	sd	s9,24(sp)
    80003f82:	e86a                	sd	s10,16(sp)
    80003f84:	e46e                	sd	s11,8(sp)
    80003f86:	1880                	add	s0,sp,112
    80003f88:	8aaa                	mv	s5,a0
    80003f8a:	8bae                	mv	s7,a1
    80003f8c:	8a32                	mv	s4,a2
    80003f8e:	8936                	mv	s2,a3
    80003f90:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003f92:	00e687bb          	addw	a5,a3,a4
    80003f96:	0ed7e263          	bltu	a5,a3,8000407a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003f9a:	00043737          	lui	a4,0x43
    80003f9e:	0ef76063          	bltu	a4,a5,8000407e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fa2:	0c0b0863          	beqz	s6,80004072 <writei+0x10e>
    80003fa6:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fa8:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003fac:	5c7d                	li	s8,-1
    80003fae:	a091                	j	80003ff2 <writei+0x8e>
    80003fb0:	020d1d93          	sll	s11,s10,0x20
    80003fb4:	020ddd93          	srl	s11,s11,0x20
    80003fb8:	05848513          	add	a0,s1,88
    80003fbc:	86ee                	mv	a3,s11
    80003fbe:	8652                	mv	a2,s4
    80003fc0:	85de                	mv	a1,s7
    80003fc2:	953a                	add	a0,a0,a4
    80003fc4:	ffffe097          	auipc	ra,0xffffe
    80003fc8:	6f8080e7          	jalr	1784(ra) # 800026bc <either_copyin>
    80003fcc:	07850263          	beq	a0,s8,80004030 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003fd0:	8526                	mv	a0,s1
    80003fd2:	00000097          	auipc	ra,0x0
    80003fd6:	75e080e7          	jalr	1886(ra) # 80004730 <log_write>
    brelse(bp);
    80003fda:	8526                	mv	a0,s1
    80003fdc:	fffff097          	auipc	ra,0xfffff
    80003fe0:	4fc080e7          	jalr	1276(ra) # 800034d8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fe4:	013d09bb          	addw	s3,s10,s3
    80003fe8:	012d093b          	addw	s2,s10,s2
    80003fec:	9a6e                	add	s4,s4,s11
    80003fee:	0569f663          	bgeu	s3,s6,8000403a <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003ff2:	00a9559b          	srlw	a1,s2,0xa
    80003ff6:	8556                	mv	a0,s5
    80003ff8:	fffff097          	auipc	ra,0xfffff
    80003ffc:	7a2080e7          	jalr	1954(ra) # 8000379a <bmap>
    80004000:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004004:	c99d                	beqz	a1,8000403a <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004006:	000aa503          	lw	a0,0(s5)
    8000400a:	fffff097          	auipc	ra,0xfffff
    8000400e:	39e080e7          	jalr	926(ra) # 800033a8 <bread>
    80004012:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004014:	3ff97713          	and	a4,s2,1023
    80004018:	40ec87bb          	subw	a5,s9,a4
    8000401c:	413b06bb          	subw	a3,s6,s3
    80004020:	8d3e                	mv	s10,a5
    80004022:	2781                	sext.w	a5,a5
    80004024:	0006861b          	sext.w	a2,a3
    80004028:	f8f674e3          	bgeu	a2,a5,80003fb0 <writei+0x4c>
    8000402c:	8d36                	mv	s10,a3
    8000402e:	b749                	j	80003fb0 <writei+0x4c>
      brelse(bp);
    80004030:	8526                	mv	a0,s1
    80004032:	fffff097          	auipc	ra,0xfffff
    80004036:	4a6080e7          	jalr	1190(ra) # 800034d8 <brelse>
  }

  if(off > ip->size)
    8000403a:	04caa783          	lw	a5,76(s5)
    8000403e:	0127f463          	bgeu	a5,s2,80004046 <writei+0xe2>
    ip->size = off;
    80004042:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004046:	8556                	mv	a0,s5
    80004048:	00000097          	auipc	ra,0x0
    8000404c:	aa4080e7          	jalr	-1372(ra) # 80003aec <iupdate>

  return tot;
    80004050:	0009851b          	sext.w	a0,s3
}
    80004054:	70a6                	ld	ra,104(sp)
    80004056:	7406                	ld	s0,96(sp)
    80004058:	64e6                	ld	s1,88(sp)
    8000405a:	6946                	ld	s2,80(sp)
    8000405c:	69a6                	ld	s3,72(sp)
    8000405e:	6a06                	ld	s4,64(sp)
    80004060:	7ae2                	ld	s5,56(sp)
    80004062:	7b42                	ld	s6,48(sp)
    80004064:	7ba2                	ld	s7,40(sp)
    80004066:	7c02                	ld	s8,32(sp)
    80004068:	6ce2                	ld	s9,24(sp)
    8000406a:	6d42                	ld	s10,16(sp)
    8000406c:	6da2                	ld	s11,8(sp)
    8000406e:	6165                	add	sp,sp,112
    80004070:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004072:	89da                	mv	s3,s6
    80004074:	bfc9                	j	80004046 <writei+0xe2>
    return -1;
    80004076:	557d                	li	a0,-1
}
    80004078:	8082                	ret
    return -1;
    8000407a:	557d                	li	a0,-1
    8000407c:	bfe1                	j	80004054 <writei+0xf0>
    return -1;
    8000407e:	557d                	li	a0,-1
    80004080:	bfd1                	j	80004054 <writei+0xf0>

0000000080004082 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004082:	1141                	add	sp,sp,-16
    80004084:	e406                	sd	ra,8(sp)
    80004086:	e022                	sd	s0,0(sp)
    80004088:	0800                	add	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000408a:	4639                	li	a2,14
    8000408c:	ffffd097          	auipc	ra,0xffffd
    80004090:	d12080e7          	jalr	-750(ra) # 80000d9e <strncmp>
}
    80004094:	60a2                	ld	ra,8(sp)
    80004096:	6402                	ld	s0,0(sp)
    80004098:	0141                	add	sp,sp,16
    8000409a:	8082                	ret

000000008000409c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000409c:	7139                	add	sp,sp,-64
    8000409e:	fc06                	sd	ra,56(sp)
    800040a0:	f822                	sd	s0,48(sp)
    800040a2:	f426                	sd	s1,40(sp)
    800040a4:	f04a                	sd	s2,32(sp)
    800040a6:	ec4e                	sd	s3,24(sp)
    800040a8:	e852                	sd	s4,16(sp)
    800040aa:	0080                	add	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800040ac:	04451703          	lh	a4,68(a0)
    800040b0:	4785                	li	a5,1
    800040b2:	00f71a63          	bne	a4,a5,800040c6 <dirlookup+0x2a>
    800040b6:	892a                	mv	s2,a0
    800040b8:	89ae                	mv	s3,a1
    800040ba:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800040bc:	457c                	lw	a5,76(a0)
    800040be:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800040c0:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040c2:	e79d                	bnez	a5,800040f0 <dirlookup+0x54>
    800040c4:	a8a5                	j	8000413c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800040c6:	00004517          	auipc	a0,0x4
    800040ca:	55250513          	add	a0,a0,1362 # 80008618 <syscalls+0x1b8>
    800040ce:	ffffc097          	auipc	ra,0xffffc
    800040d2:	46e080e7          	jalr	1134(ra) # 8000053c <panic>
      panic("dirlookup read");
    800040d6:	00004517          	auipc	a0,0x4
    800040da:	55a50513          	add	a0,a0,1370 # 80008630 <syscalls+0x1d0>
    800040de:	ffffc097          	auipc	ra,0xffffc
    800040e2:	45e080e7          	jalr	1118(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040e6:	24c1                	addw	s1,s1,16
    800040e8:	04c92783          	lw	a5,76(s2)
    800040ec:	04f4f763          	bgeu	s1,a5,8000413a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040f0:	4741                	li	a4,16
    800040f2:	86a6                	mv	a3,s1
    800040f4:	fc040613          	add	a2,s0,-64
    800040f8:	4581                	li	a1,0
    800040fa:	854a                	mv	a0,s2
    800040fc:	00000097          	auipc	ra,0x0
    80004100:	d70080e7          	jalr	-656(ra) # 80003e6c <readi>
    80004104:	47c1                	li	a5,16
    80004106:	fcf518e3          	bne	a0,a5,800040d6 <dirlookup+0x3a>
    if(de.inum == 0)
    8000410a:	fc045783          	lhu	a5,-64(s0)
    8000410e:	dfe1                	beqz	a5,800040e6 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004110:	fc240593          	add	a1,s0,-62
    80004114:	854e                	mv	a0,s3
    80004116:	00000097          	auipc	ra,0x0
    8000411a:	f6c080e7          	jalr	-148(ra) # 80004082 <namecmp>
    8000411e:	f561                	bnez	a0,800040e6 <dirlookup+0x4a>
      if(poff)
    80004120:	000a0463          	beqz	s4,80004128 <dirlookup+0x8c>
        *poff = off;
    80004124:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004128:	fc045583          	lhu	a1,-64(s0)
    8000412c:	00092503          	lw	a0,0(s2)
    80004130:	fffff097          	auipc	ra,0xfffff
    80004134:	754080e7          	jalr	1876(ra) # 80003884 <iget>
    80004138:	a011                	j	8000413c <dirlookup+0xa0>
  return 0;
    8000413a:	4501                	li	a0,0
}
    8000413c:	70e2                	ld	ra,56(sp)
    8000413e:	7442                	ld	s0,48(sp)
    80004140:	74a2                	ld	s1,40(sp)
    80004142:	7902                	ld	s2,32(sp)
    80004144:	69e2                	ld	s3,24(sp)
    80004146:	6a42                	ld	s4,16(sp)
    80004148:	6121                	add	sp,sp,64
    8000414a:	8082                	ret

000000008000414c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000414c:	711d                	add	sp,sp,-96
    8000414e:	ec86                	sd	ra,88(sp)
    80004150:	e8a2                	sd	s0,80(sp)
    80004152:	e4a6                	sd	s1,72(sp)
    80004154:	e0ca                	sd	s2,64(sp)
    80004156:	fc4e                	sd	s3,56(sp)
    80004158:	f852                	sd	s4,48(sp)
    8000415a:	f456                	sd	s5,40(sp)
    8000415c:	f05a                	sd	s6,32(sp)
    8000415e:	ec5e                	sd	s7,24(sp)
    80004160:	e862                	sd	s8,16(sp)
    80004162:	e466                	sd	s9,8(sp)
    80004164:	1080                	add	s0,sp,96
    80004166:	84aa                	mv	s1,a0
    80004168:	8b2e                	mv	s6,a1
    8000416a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000416c:	00054703          	lbu	a4,0(a0)
    80004170:	02f00793          	li	a5,47
    80004174:	02f70263          	beq	a4,a5,80004198 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004178:	ffffe097          	auipc	ra,0xffffe
    8000417c:	858080e7          	jalr	-1960(ra) # 800019d0 <myproc>
    80004180:	15053503          	ld	a0,336(a0)
    80004184:	00000097          	auipc	ra,0x0
    80004188:	9f6080e7          	jalr	-1546(ra) # 80003b7a <idup>
    8000418c:	8a2a                	mv	s4,a0
  while(*path == '/')
    8000418e:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004192:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004194:	4b85                	li	s7,1
    80004196:	a875                	j	80004252 <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80004198:	4585                	li	a1,1
    8000419a:	4505                	li	a0,1
    8000419c:	fffff097          	auipc	ra,0xfffff
    800041a0:	6e8080e7          	jalr	1768(ra) # 80003884 <iget>
    800041a4:	8a2a                	mv	s4,a0
    800041a6:	b7e5                	j	8000418e <namex+0x42>
      iunlockput(ip);
    800041a8:	8552                	mv	a0,s4
    800041aa:	00000097          	auipc	ra,0x0
    800041ae:	c70080e7          	jalr	-912(ra) # 80003e1a <iunlockput>
      return 0;
    800041b2:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800041b4:	8552                	mv	a0,s4
    800041b6:	60e6                	ld	ra,88(sp)
    800041b8:	6446                	ld	s0,80(sp)
    800041ba:	64a6                	ld	s1,72(sp)
    800041bc:	6906                	ld	s2,64(sp)
    800041be:	79e2                	ld	s3,56(sp)
    800041c0:	7a42                	ld	s4,48(sp)
    800041c2:	7aa2                	ld	s5,40(sp)
    800041c4:	7b02                	ld	s6,32(sp)
    800041c6:	6be2                	ld	s7,24(sp)
    800041c8:	6c42                	ld	s8,16(sp)
    800041ca:	6ca2                	ld	s9,8(sp)
    800041cc:	6125                	add	sp,sp,96
    800041ce:	8082                	ret
      iunlock(ip);
    800041d0:	8552                	mv	a0,s4
    800041d2:	00000097          	auipc	ra,0x0
    800041d6:	aa8080e7          	jalr	-1368(ra) # 80003c7a <iunlock>
      return ip;
    800041da:	bfe9                	j	800041b4 <namex+0x68>
      iunlockput(ip);
    800041dc:	8552                	mv	a0,s4
    800041de:	00000097          	auipc	ra,0x0
    800041e2:	c3c080e7          	jalr	-964(ra) # 80003e1a <iunlockput>
      return 0;
    800041e6:	8a4e                	mv	s4,s3
    800041e8:	b7f1                	j	800041b4 <namex+0x68>
  len = path - s;
    800041ea:	40998633          	sub	a2,s3,s1
    800041ee:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800041f2:	099c5863          	bge	s8,s9,80004282 <namex+0x136>
    memmove(name, s, DIRSIZ);
    800041f6:	4639                	li	a2,14
    800041f8:	85a6                	mv	a1,s1
    800041fa:	8556                	mv	a0,s5
    800041fc:	ffffd097          	auipc	ra,0xffffd
    80004200:	b2e080e7          	jalr	-1234(ra) # 80000d2a <memmove>
    80004204:	84ce                	mv	s1,s3
  while(*path == '/')
    80004206:	0004c783          	lbu	a5,0(s1)
    8000420a:	01279763          	bne	a5,s2,80004218 <namex+0xcc>
    path++;
    8000420e:	0485                	add	s1,s1,1
  while(*path == '/')
    80004210:	0004c783          	lbu	a5,0(s1)
    80004214:	ff278de3          	beq	a5,s2,8000420e <namex+0xc2>
    ilock(ip);
    80004218:	8552                	mv	a0,s4
    8000421a:	00000097          	auipc	ra,0x0
    8000421e:	99e080e7          	jalr	-1634(ra) # 80003bb8 <ilock>
    if(ip->type != T_DIR){
    80004222:	044a1783          	lh	a5,68(s4)
    80004226:	f97791e3          	bne	a5,s7,800041a8 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    8000422a:	000b0563          	beqz	s6,80004234 <namex+0xe8>
    8000422e:	0004c783          	lbu	a5,0(s1)
    80004232:	dfd9                	beqz	a5,800041d0 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004234:	4601                	li	a2,0
    80004236:	85d6                	mv	a1,s5
    80004238:	8552                	mv	a0,s4
    8000423a:	00000097          	auipc	ra,0x0
    8000423e:	e62080e7          	jalr	-414(ra) # 8000409c <dirlookup>
    80004242:	89aa                	mv	s3,a0
    80004244:	dd41                	beqz	a0,800041dc <namex+0x90>
    iunlockput(ip);
    80004246:	8552                	mv	a0,s4
    80004248:	00000097          	auipc	ra,0x0
    8000424c:	bd2080e7          	jalr	-1070(ra) # 80003e1a <iunlockput>
    ip = next;
    80004250:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004252:	0004c783          	lbu	a5,0(s1)
    80004256:	01279763          	bne	a5,s2,80004264 <namex+0x118>
    path++;
    8000425a:	0485                	add	s1,s1,1
  while(*path == '/')
    8000425c:	0004c783          	lbu	a5,0(s1)
    80004260:	ff278de3          	beq	a5,s2,8000425a <namex+0x10e>
  if(*path == 0)
    80004264:	cb9d                	beqz	a5,8000429a <namex+0x14e>
  while(*path != '/' && *path != 0)
    80004266:	0004c783          	lbu	a5,0(s1)
    8000426a:	89a6                	mv	s3,s1
  len = path - s;
    8000426c:	4c81                	li	s9,0
    8000426e:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80004270:	01278963          	beq	a5,s2,80004282 <namex+0x136>
    80004274:	dbbd                	beqz	a5,800041ea <namex+0x9e>
    path++;
    80004276:	0985                	add	s3,s3,1
  while(*path != '/' && *path != 0)
    80004278:	0009c783          	lbu	a5,0(s3)
    8000427c:	ff279ce3          	bne	a5,s2,80004274 <namex+0x128>
    80004280:	b7ad                	j	800041ea <namex+0x9e>
    memmove(name, s, len);
    80004282:	2601                	sext.w	a2,a2
    80004284:	85a6                	mv	a1,s1
    80004286:	8556                	mv	a0,s5
    80004288:	ffffd097          	auipc	ra,0xffffd
    8000428c:	aa2080e7          	jalr	-1374(ra) # 80000d2a <memmove>
    name[len] = 0;
    80004290:	9cd6                	add	s9,s9,s5
    80004292:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004296:	84ce                	mv	s1,s3
    80004298:	b7bd                	j	80004206 <namex+0xba>
  if(nameiparent){
    8000429a:	f00b0de3          	beqz	s6,800041b4 <namex+0x68>
    iput(ip);
    8000429e:	8552                	mv	a0,s4
    800042a0:	00000097          	auipc	ra,0x0
    800042a4:	ad2080e7          	jalr	-1326(ra) # 80003d72 <iput>
    return 0;
    800042a8:	4a01                	li	s4,0
    800042aa:	b729                	j	800041b4 <namex+0x68>

00000000800042ac <dirlink>:
{
    800042ac:	7139                	add	sp,sp,-64
    800042ae:	fc06                	sd	ra,56(sp)
    800042b0:	f822                	sd	s0,48(sp)
    800042b2:	f426                	sd	s1,40(sp)
    800042b4:	f04a                	sd	s2,32(sp)
    800042b6:	ec4e                	sd	s3,24(sp)
    800042b8:	e852                	sd	s4,16(sp)
    800042ba:	0080                	add	s0,sp,64
    800042bc:	892a                	mv	s2,a0
    800042be:	8a2e                	mv	s4,a1
    800042c0:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800042c2:	4601                	li	a2,0
    800042c4:	00000097          	auipc	ra,0x0
    800042c8:	dd8080e7          	jalr	-552(ra) # 8000409c <dirlookup>
    800042cc:	e93d                	bnez	a0,80004342 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042ce:	04c92483          	lw	s1,76(s2)
    800042d2:	c49d                	beqz	s1,80004300 <dirlink+0x54>
    800042d4:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042d6:	4741                	li	a4,16
    800042d8:	86a6                	mv	a3,s1
    800042da:	fc040613          	add	a2,s0,-64
    800042de:	4581                	li	a1,0
    800042e0:	854a                	mv	a0,s2
    800042e2:	00000097          	auipc	ra,0x0
    800042e6:	b8a080e7          	jalr	-1142(ra) # 80003e6c <readi>
    800042ea:	47c1                	li	a5,16
    800042ec:	06f51163          	bne	a0,a5,8000434e <dirlink+0xa2>
    if(de.inum == 0)
    800042f0:	fc045783          	lhu	a5,-64(s0)
    800042f4:	c791                	beqz	a5,80004300 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042f6:	24c1                	addw	s1,s1,16
    800042f8:	04c92783          	lw	a5,76(s2)
    800042fc:	fcf4ede3          	bltu	s1,a5,800042d6 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004300:	4639                	li	a2,14
    80004302:	85d2                	mv	a1,s4
    80004304:	fc240513          	add	a0,s0,-62
    80004308:	ffffd097          	auipc	ra,0xffffd
    8000430c:	ad2080e7          	jalr	-1326(ra) # 80000dda <strncpy>
  de.inum = inum;
    80004310:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004314:	4741                	li	a4,16
    80004316:	86a6                	mv	a3,s1
    80004318:	fc040613          	add	a2,s0,-64
    8000431c:	4581                	li	a1,0
    8000431e:	854a                	mv	a0,s2
    80004320:	00000097          	auipc	ra,0x0
    80004324:	c44080e7          	jalr	-956(ra) # 80003f64 <writei>
    80004328:	1541                	add	a0,a0,-16
    8000432a:	00a03533          	snez	a0,a0
    8000432e:	40a00533          	neg	a0,a0
}
    80004332:	70e2                	ld	ra,56(sp)
    80004334:	7442                	ld	s0,48(sp)
    80004336:	74a2                	ld	s1,40(sp)
    80004338:	7902                	ld	s2,32(sp)
    8000433a:	69e2                	ld	s3,24(sp)
    8000433c:	6a42                	ld	s4,16(sp)
    8000433e:	6121                	add	sp,sp,64
    80004340:	8082                	ret
    iput(ip);
    80004342:	00000097          	auipc	ra,0x0
    80004346:	a30080e7          	jalr	-1488(ra) # 80003d72 <iput>
    return -1;
    8000434a:	557d                	li	a0,-1
    8000434c:	b7dd                	j	80004332 <dirlink+0x86>
      panic("dirlink read");
    8000434e:	00004517          	auipc	a0,0x4
    80004352:	2f250513          	add	a0,a0,754 # 80008640 <syscalls+0x1e0>
    80004356:	ffffc097          	auipc	ra,0xffffc
    8000435a:	1e6080e7          	jalr	486(ra) # 8000053c <panic>

000000008000435e <namei>:

struct inode*
namei(char *path)
{
    8000435e:	1101                	add	sp,sp,-32
    80004360:	ec06                	sd	ra,24(sp)
    80004362:	e822                	sd	s0,16(sp)
    80004364:	1000                	add	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004366:	fe040613          	add	a2,s0,-32
    8000436a:	4581                	li	a1,0
    8000436c:	00000097          	auipc	ra,0x0
    80004370:	de0080e7          	jalr	-544(ra) # 8000414c <namex>
}
    80004374:	60e2                	ld	ra,24(sp)
    80004376:	6442                	ld	s0,16(sp)
    80004378:	6105                	add	sp,sp,32
    8000437a:	8082                	ret

000000008000437c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000437c:	1141                	add	sp,sp,-16
    8000437e:	e406                	sd	ra,8(sp)
    80004380:	e022                	sd	s0,0(sp)
    80004382:	0800                	add	s0,sp,16
    80004384:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004386:	4585                	li	a1,1
    80004388:	00000097          	auipc	ra,0x0
    8000438c:	dc4080e7          	jalr	-572(ra) # 8000414c <namex>
}
    80004390:	60a2                	ld	ra,8(sp)
    80004392:	6402                	ld	s0,0(sp)
    80004394:	0141                	add	sp,sp,16
    80004396:	8082                	ret

0000000080004398 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004398:	1101                	add	sp,sp,-32
    8000439a:	ec06                	sd	ra,24(sp)
    8000439c:	e822                	sd	s0,16(sp)
    8000439e:	e426                	sd	s1,8(sp)
    800043a0:	e04a                	sd	s2,0(sp)
    800043a2:	1000                	add	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800043a4:	0001d917          	auipc	s2,0x1d
    800043a8:	f8c90913          	add	s2,s2,-116 # 80021330 <log>
    800043ac:	01892583          	lw	a1,24(s2)
    800043b0:	02892503          	lw	a0,40(s2)
    800043b4:	fffff097          	auipc	ra,0xfffff
    800043b8:	ff4080e7          	jalr	-12(ra) # 800033a8 <bread>
    800043bc:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800043be:	02c92603          	lw	a2,44(s2)
    800043c2:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800043c4:	00c05f63          	blez	a2,800043e2 <write_head+0x4a>
    800043c8:	0001d717          	auipc	a4,0x1d
    800043cc:	f9870713          	add	a4,a4,-104 # 80021360 <log+0x30>
    800043d0:	87aa                	mv	a5,a0
    800043d2:	060a                	sll	a2,a2,0x2
    800043d4:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    800043d6:	4314                	lw	a3,0(a4)
    800043d8:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    800043da:	0711                	add	a4,a4,4
    800043dc:	0791                	add	a5,a5,4
    800043de:	fec79ce3          	bne	a5,a2,800043d6 <write_head+0x3e>
  }
  bwrite(buf);
    800043e2:	8526                	mv	a0,s1
    800043e4:	fffff097          	auipc	ra,0xfffff
    800043e8:	0b6080e7          	jalr	182(ra) # 8000349a <bwrite>
  brelse(buf);
    800043ec:	8526                	mv	a0,s1
    800043ee:	fffff097          	auipc	ra,0xfffff
    800043f2:	0ea080e7          	jalr	234(ra) # 800034d8 <brelse>
}
    800043f6:	60e2                	ld	ra,24(sp)
    800043f8:	6442                	ld	s0,16(sp)
    800043fa:	64a2                	ld	s1,8(sp)
    800043fc:	6902                	ld	s2,0(sp)
    800043fe:	6105                	add	sp,sp,32
    80004400:	8082                	ret

0000000080004402 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004402:	0001d797          	auipc	a5,0x1d
    80004406:	f5a7a783          	lw	a5,-166(a5) # 8002135c <log+0x2c>
    8000440a:	0af05d63          	blez	a5,800044c4 <install_trans+0xc2>
{
    8000440e:	7139                	add	sp,sp,-64
    80004410:	fc06                	sd	ra,56(sp)
    80004412:	f822                	sd	s0,48(sp)
    80004414:	f426                	sd	s1,40(sp)
    80004416:	f04a                	sd	s2,32(sp)
    80004418:	ec4e                	sd	s3,24(sp)
    8000441a:	e852                	sd	s4,16(sp)
    8000441c:	e456                	sd	s5,8(sp)
    8000441e:	e05a                	sd	s6,0(sp)
    80004420:	0080                	add	s0,sp,64
    80004422:	8b2a                	mv	s6,a0
    80004424:	0001da97          	auipc	s5,0x1d
    80004428:	f3ca8a93          	add	s5,s5,-196 # 80021360 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000442c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000442e:	0001d997          	auipc	s3,0x1d
    80004432:	f0298993          	add	s3,s3,-254 # 80021330 <log>
    80004436:	a00d                	j	80004458 <install_trans+0x56>
    brelse(lbuf);
    80004438:	854a                	mv	a0,s2
    8000443a:	fffff097          	auipc	ra,0xfffff
    8000443e:	09e080e7          	jalr	158(ra) # 800034d8 <brelse>
    brelse(dbuf);
    80004442:	8526                	mv	a0,s1
    80004444:	fffff097          	auipc	ra,0xfffff
    80004448:	094080e7          	jalr	148(ra) # 800034d8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000444c:	2a05                	addw	s4,s4,1
    8000444e:	0a91                	add	s5,s5,4
    80004450:	02c9a783          	lw	a5,44(s3)
    80004454:	04fa5e63          	bge	s4,a5,800044b0 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004458:	0189a583          	lw	a1,24(s3)
    8000445c:	014585bb          	addw	a1,a1,s4
    80004460:	2585                	addw	a1,a1,1
    80004462:	0289a503          	lw	a0,40(s3)
    80004466:	fffff097          	auipc	ra,0xfffff
    8000446a:	f42080e7          	jalr	-190(ra) # 800033a8 <bread>
    8000446e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004470:	000aa583          	lw	a1,0(s5)
    80004474:	0289a503          	lw	a0,40(s3)
    80004478:	fffff097          	auipc	ra,0xfffff
    8000447c:	f30080e7          	jalr	-208(ra) # 800033a8 <bread>
    80004480:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004482:	40000613          	li	a2,1024
    80004486:	05890593          	add	a1,s2,88
    8000448a:	05850513          	add	a0,a0,88
    8000448e:	ffffd097          	auipc	ra,0xffffd
    80004492:	89c080e7          	jalr	-1892(ra) # 80000d2a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004496:	8526                	mv	a0,s1
    80004498:	fffff097          	auipc	ra,0xfffff
    8000449c:	002080e7          	jalr	2(ra) # 8000349a <bwrite>
    if(recovering == 0)
    800044a0:	f80b1ce3          	bnez	s6,80004438 <install_trans+0x36>
      bunpin(dbuf);
    800044a4:	8526                	mv	a0,s1
    800044a6:	fffff097          	auipc	ra,0xfffff
    800044aa:	10a080e7          	jalr	266(ra) # 800035b0 <bunpin>
    800044ae:	b769                	j	80004438 <install_trans+0x36>
}
    800044b0:	70e2                	ld	ra,56(sp)
    800044b2:	7442                	ld	s0,48(sp)
    800044b4:	74a2                	ld	s1,40(sp)
    800044b6:	7902                	ld	s2,32(sp)
    800044b8:	69e2                	ld	s3,24(sp)
    800044ba:	6a42                	ld	s4,16(sp)
    800044bc:	6aa2                	ld	s5,8(sp)
    800044be:	6b02                	ld	s6,0(sp)
    800044c0:	6121                	add	sp,sp,64
    800044c2:	8082                	ret
    800044c4:	8082                	ret

00000000800044c6 <initlog>:
{
    800044c6:	7179                	add	sp,sp,-48
    800044c8:	f406                	sd	ra,40(sp)
    800044ca:	f022                	sd	s0,32(sp)
    800044cc:	ec26                	sd	s1,24(sp)
    800044ce:	e84a                	sd	s2,16(sp)
    800044d0:	e44e                	sd	s3,8(sp)
    800044d2:	1800                	add	s0,sp,48
    800044d4:	892a                	mv	s2,a0
    800044d6:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800044d8:	0001d497          	auipc	s1,0x1d
    800044dc:	e5848493          	add	s1,s1,-424 # 80021330 <log>
    800044e0:	00004597          	auipc	a1,0x4
    800044e4:	17058593          	add	a1,a1,368 # 80008650 <syscalls+0x1f0>
    800044e8:	8526                	mv	a0,s1
    800044ea:	ffffc097          	auipc	ra,0xffffc
    800044ee:	658080e7          	jalr	1624(ra) # 80000b42 <initlock>
  log.start = sb->logstart;
    800044f2:	0149a583          	lw	a1,20(s3)
    800044f6:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800044f8:	0109a783          	lw	a5,16(s3)
    800044fc:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800044fe:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004502:	854a                	mv	a0,s2
    80004504:	fffff097          	auipc	ra,0xfffff
    80004508:	ea4080e7          	jalr	-348(ra) # 800033a8 <bread>
  log.lh.n = lh->n;
    8000450c:	4d30                	lw	a2,88(a0)
    8000450e:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004510:	00c05f63          	blez	a2,8000452e <initlog+0x68>
    80004514:	87aa                	mv	a5,a0
    80004516:	0001d717          	auipc	a4,0x1d
    8000451a:	e4a70713          	add	a4,a4,-438 # 80021360 <log+0x30>
    8000451e:	060a                	sll	a2,a2,0x2
    80004520:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80004522:	4ff4                	lw	a3,92(a5)
    80004524:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004526:	0791                	add	a5,a5,4
    80004528:	0711                	add	a4,a4,4
    8000452a:	fec79ce3          	bne	a5,a2,80004522 <initlog+0x5c>
  brelse(buf);
    8000452e:	fffff097          	auipc	ra,0xfffff
    80004532:	faa080e7          	jalr	-86(ra) # 800034d8 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004536:	4505                	li	a0,1
    80004538:	00000097          	auipc	ra,0x0
    8000453c:	eca080e7          	jalr	-310(ra) # 80004402 <install_trans>
  log.lh.n = 0;
    80004540:	0001d797          	auipc	a5,0x1d
    80004544:	e007ae23          	sw	zero,-484(a5) # 8002135c <log+0x2c>
  write_head(); // clear the log
    80004548:	00000097          	auipc	ra,0x0
    8000454c:	e50080e7          	jalr	-432(ra) # 80004398 <write_head>
}
    80004550:	70a2                	ld	ra,40(sp)
    80004552:	7402                	ld	s0,32(sp)
    80004554:	64e2                	ld	s1,24(sp)
    80004556:	6942                	ld	s2,16(sp)
    80004558:	69a2                	ld	s3,8(sp)
    8000455a:	6145                	add	sp,sp,48
    8000455c:	8082                	ret

000000008000455e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000455e:	1101                	add	sp,sp,-32
    80004560:	ec06                	sd	ra,24(sp)
    80004562:	e822                	sd	s0,16(sp)
    80004564:	e426                	sd	s1,8(sp)
    80004566:	e04a                	sd	s2,0(sp)
    80004568:	1000                	add	s0,sp,32
  acquire(&log.lock);
    8000456a:	0001d517          	auipc	a0,0x1d
    8000456e:	dc650513          	add	a0,a0,-570 # 80021330 <log>
    80004572:	ffffc097          	auipc	ra,0xffffc
    80004576:	660080e7          	jalr	1632(ra) # 80000bd2 <acquire>
  while(1){
    if(log.committing){
    8000457a:	0001d497          	auipc	s1,0x1d
    8000457e:	db648493          	add	s1,s1,-586 # 80021330 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004582:	4979                	li	s2,30
    80004584:	a039                	j	80004592 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004586:	85a6                	mv	a1,s1
    80004588:	8526                	mv	a0,s1
    8000458a:	ffffe097          	auipc	ra,0xffffe
    8000458e:	cc8080e7          	jalr	-824(ra) # 80002252 <sleep>
    if(log.committing){
    80004592:	50dc                	lw	a5,36(s1)
    80004594:	fbed                	bnez	a5,80004586 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004596:	5098                	lw	a4,32(s1)
    80004598:	2705                	addw	a4,a4,1
    8000459a:	0027179b          	sllw	a5,a4,0x2
    8000459e:	9fb9                	addw	a5,a5,a4
    800045a0:	0017979b          	sllw	a5,a5,0x1
    800045a4:	54d4                	lw	a3,44(s1)
    800045a6:	9fb5                	addw	a5,a5,a3
    800045a8:	00f95963          	bge	s2,a5,800045ba <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800045ac:	85a6                	mv	a1,s1
    800045ae:	8526                	mv	a0,s1
    800045b0:	ffffe097          	auipc	ra,0xffffe
    800045b4:	ca2080e7          	jalr	-862(ra) # 80002252 <sleep>
    800045b8:	bfe9                	j	80004592 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800045ba:	0001d517          	auipc	a0,0x1d
    800045be:	d7650513          	add	a0,a0,-650 # 80021330 <log>
    800045c2:	d118                	sw	a4,32(a0)
      release(&log.lock);
    800045c4:	ffffc097          	auipc	ra,0xffffc
    800045c8:	6c2080e7          	jalr	1730(ra) # 80000c86 <release>
      break;
    }
  }
}
    800045cc:	60e2                	ld	ra,24(sp)
    800045ce:	6442                	ld	s0,16(sp)
    800045d0:	64a2                	ld	s1,8(sp)
    800045d2:	6902                	ld	s2,0(sp)
    800045d4:	6105                	add	sp,sp,32
    800045d6:	8082                	ret

00000000800045d8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800045d8:	7139                	add	sp,sp,-64
    800045da:	fc06                	sd	ra,56(sp)
    800045dc:	f822                	sd	s0,48(sp)
    800045de:	f426                	sd	s1,40(sp)
    800045e0:	f04a                	sd	s2,32(sp)
    800045e2:	ec4e                	sd	s3,24(sp)
    800045e4:	e852                	sd	s4,16(sp)
    800045e6:	e456                	sd	s5,8(sp)
    800045e8:	0080                	add	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800045ea:	0001d497          	auipc	s1,0x1d
    800045ee:	d4648493          	add	s1,s1,-698 # 80021330 <log>
    800045f2:	8526                	mv	a0,s1
    800045f4:	ffffc097          	auipc	ra,0xffffc
    800045f8:	5de080e7          	jalr	1502(ra) # 80000bd2 <acquire>
  log.outstanding -= 1;
    800045fc:	509c                	lw	a5,32(s1)
    800045fe:	37fd                	addw	a5,a5,-1
    80004600:	0007891b          	sext.w	s2,a5
    80004604:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004606:	50dc                	lw	a5,36(s1)
    80004608:	e7b9                	bnez	a5,80004656 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000460a:	04091e63          	bnez	s2,80004666 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000460e:	0001d497          	auipc	s1,0x1d
    80004612:	d2248493          	add	s1,s1,-734 # 80021330 <log>
    80004616:	4785                	li	a5,1
    80004618:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000461a:	8526                	mv	a0,s1
    8000461c:	ffffc097          	auipc	ra,0xffffc
    80004620:	66a080e7          	jalr	1642(ra) # 80000c86 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004624:	54dc                	lw	a5,44(s1)
    80004626:	06f04763          	bgtz	a5,80004694 <end_op+0xbc>
    acquire(&log.lock);
    8000462a:	0001d497          	auipc	s1,0x1d
    8000462e:	d0648493          	add	s1,s1,-762 # 80021330 <log>
    80004632:	8526                	mv	a0,s1
    80004634:	ffffc097          	auipc	ra,0xffffc
    80004638:	59e080e7          	jalr	1438(ra) # 80000bd2 <acquire>
    log.committing = 0;
    8000463c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004640:	8526                	mv	a0,s1
    80004642:	ffffe097          	auipc	ra,0xffffe
    80004646:	c74080e7          	jalr	-908(ra) # 800022b6 <wakeup>
    release(&log.lock);
    8000464a:	8526                	mv	a0,s1
    8000464c:	ffffc097          	auipc	ra,0xffffc
    80004650:	63a080e7          	jalr	1594(ra) # 80000c86 <release>
}
    80004654:	a03d                	j	80004682 <end_op+0xaa>
    panic("log.committing");
    80004656:	00004517          	auipc	a0,0x4
    8000465a:	00250513          	add	a0,a0,2 # 80008658 <syscalls+0x1f8>
    8000465e:	ffffc097          	auipc	ra,0xffffc
    80004662:	ede080e7          	jalr	-290(ra) # 8000053c <panic>
    wakeup(&log);
    80004666:	0001d497          	auipc	s1,0x1d
    8000466a:	cca48493          	add	s1,s1,-822 # 80021330 <log>
    8000466e:	8526                	mv	a0,s1
    80004670:	ffffe097          	auipc	ra,0xffffe
    80004674:	c46080e7          	jalr	-954(ra) # 800022b6 <wakeup>
  release(&log.lock);
    80004678:	8526                	mv	a0,s1
    8000467a:	ffffc097          	auipc	ra,0xffffc
    8000467e:	60c080e7          	jalr	1548(ra) # 80000c86 <release>
}
    80004682:	70e2                	ld	ra,56(sp)
    80004684:	7442                	ld	s0,48(sp)
    80004686:	74a2                	ld	s1,40(sp)
    80004688:	7902                	ld	s2,32(sp)
    8000468a:	69e2                	ld	s3,24(sp)
    8000468c:	6a42                	ld	s4,16(sp)
    8000468e:	6aa2                	ld	s5,8(sp)
    80004690:	6121                	add	sp,sp,64
    80004692:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004694:	0001da97          	auipc	s5,0x1d
    80004698:	ccca8a93          	add	s5,s5,-820 # 80021360 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000469c:	0001da17          	auipc	s4,0x1d
    800046a0:	c94a0a13          	add	s4,s4,-876 # 80021330 <log>
    800046a4:	018a2583          	lw	a1,24(s4)
    800046a8:	012585bb          	addw	a1,a1,s2
    800046ac:	2585                	addw	a1,a1,1
    800046ae:	028a2503          	lw	a0,40(s4)
    800046b2:	fffff097          	auipc	ra,0xfffff
    800046b6:	cf6080e7          	jalr	-778(ra) # 800033a8 <bread>
    800046ba:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800046bc:	000aa583          	lw	a1,0(s5)
    800046c0:	028a2503          	lw	a0,40(s4)
    800046c4:	fffff097          	auipc	ra,0xfffff
    800046c8:	ce4080e7          	jalr	-796(ra) # 800033a8 <bread>
    800046cc:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800046ce:	40000613          	li	a2,1024
    800046d2:	05850593          	add	a1,a0,88
    800046d6:	05848513          	add	a0,s1,88
    800046da:	ffffc097          	auipc	ra,0xffffc
    800046de:	650080e7          	jalr	1616(ra) # 80000d2a <memmove>
    bwrite(to);  // write the log
    800046e2:	8526                	mv	a0,s1
    800046e4:	fffff097          	auipc	ra,0xfffff
    800046e8:	db6080e7          	jalr	-586(ra) # 8000349a <bwrite>
    brelse(from);
    800046ec:	854e                	mv	a0,s3
    800046ee:	fffff097          	auipc	ra,0xfffff
    800046f2:	dea080e7          	jalr	-534(ra) # 800034d8 <brelse>
    brelse(to);
    800046f6:	8526                	mv	a0,s1
    800046f8:	fffff097          	auipc	ra,0xfffff
    800046fc:	de0080e7          	jalr	-544(ra) # 800034d8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004700:	2905                	addw	s2,s2,1
    80004702:	0a91                	add	s5,s5,4
    80004704:	02ca2783          	lw	a5,44(s4)
    80004708:	f8f94ee3          	blt	s2,a5,800046a4 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000470c:	00000097          	auipc	ra,0x0
    80004710:	c8c080e7          	jalr	-884(ra) # 80004398 <write_head>
    install_trans(0); // Now install writes to home locations
    80004714:	4501                	li	a0,0
    80004716:	00000097          	auipc	ra,0x0
    8000471a:	cec080e7          	jalr	-788(ra) # 80004402 <install_trans>
    log.lh.n = 0;
    8000471e:	0001d797          	auipc	a5,0x1d
    80004722:	c207af23          	sw	zero,-962(a5) # 8002135c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004726:	00000097          	auipc	ra,0x0
    8000472a:	c72080e7          	jalr	-910(ra) # 80004398 <write_head>
    8000472e:	bdf5                	j	8000462a <end_op+0x52>

0000000080004730 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004730:	1101                	add	sp,sp,-32
    80004732:	ec06                	sd	ra,24(sp)
    80004734:	e822                	sd	s0,16(sp)
    80004736:	e426                	sd	s1,8(sp)
    80004738:	e04a                	sd	s2,0(sp)
    8000473a:	1000                	add	s0,sp,32
    8000473c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000473e:	0001d917          	auipc	s2,0x1d
    80004742:	bf290913          	add	s2,s2,-1038 # 80021330 <log>
    80004746:	854a                	mv	a0,s2
    80004748:	ffffc097          	auipc	ra,0xffffc
    8000474c:	48a080e7          	jalr	1162(ra) # 80000bd2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004750:	02c92603          	lw	a2,44(s2)
    80004754:	47f5                	li	a5,29
    80004756:	06c7c563          	blt	a5,a2,800047c0 <log_write+0x90>
    8000475a:	0001d797          	auipc	a5,0x1d
    8000475e:	bf27a783          	lw	a5,-1038(a5) # 8002134c <log+0x1c>
    80004762:	37fd                	addw	a5,a5,-1
    80004764:	04f65e63          	bge	a2,a5,800047c0 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004768:	0001d797          	auipc	a5,0x1d
    8000476c:	be87a783          	lw	a5,-1048(a5) # 80021350 <log+0x20>
    80004770:	06f05063          	blez	a5,800047d0 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004774:	4781                	li	a5,0
    80004776:	06c05563          	blez	a2,800047e0 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000477a:	44cc                	lw	a1,12(s1)
    8000477c:	0001d717          	auipc	a4,0x1d
    80004780:	be470713          	add	a4,a4,-1052 # 80021360 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004784:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004786:	4314                	lw	a3,0(a4)
    80004788:	04b68c63          	beq	a3,a1,800047e0 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000478c:	2785                	addw	a5,a5,1
    8000478e:	0711                	add	a4,a4,4
    80004790:	fef61be3          	bne	a2,a5,80004786 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004794:	0621                	add	a2,a2,8
    80004796:	060a                	sll	a2,a2,0x2
    80004798:	0001d797          	auipc	a5,0x1d
    8000479c:	b9878793          	add	a5,a5,-1128 # 80021330 <log>
    800047a0:	97b2                	add	a5,a5,a2
    800047a2:	44d8                	lw	a4,12(s1)
    800047a4:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800047a6:	8526                	mv	a0,s1
    800047a8:	fffff097          	auipc	ra,0xfffff
    800047ac:	dcc080e7          	jalr	-564(ra) # 80003574 <bpin>
    log.lh.n++;
    800047b0:	0001d717          	auipc	a4,0x1d
    800047b4:	b8070713          	add	a4,a4,-1152 # 80021330 <log>
    800047b8:	575c                	lw	a5,44(a4)
    800047ba:	2785                	addw	a5,a5,1
    800047bc:	d75c                	sw	a5,44(a4)
    800047be:	a82d                	j	800047f8 <log_write+0xc8>
    panic("too big a transaction");
    800047c0:	00004517          	auipc	a0,0x4
    800047c4:	ea850513          	add	a0,a0,-344 # 80008668 <syscalls+0x208>
    800047c8:	ffffc097          	auipc	ra,0xffffc
    800047cc:	d74080e7          	jalr	-652(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    800047d0:	00004517          	auipc	a0,0x4
    800047d4:	eb050513          	add	a0,a0,-336 # 80008680 <syscalls+0x220>
    800047d8:	ffffc097          	auipc	ra,0xffffc
    800047dc:	d64080e7          	jalr	-668(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    800047e0:	00878693          	add	a3,a5,8
    800047e4:	068a                	sll	a3,a3,0x2
    800047e6:	0001d717          	auipc	a4,0x1d
    800047ea:	b4a70713          	add	a4,a4,-1206 # 80021330 <log>
    800047ee:	9736                	add	a4,a4,a3
    800047f0:	44d4                	lw	a3,12(s1)
    800047f2:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800047f4:	faf609e3          	beq	a2,a5,800047a6 <log_write+0x76>
  }
  release(&log.lock);
    800047f8:	0001d517          	auipc	a0,0x1d
    800047fc:	b3850513          	add	a0,a0,-1224 # 80021330 <log>
    80004800:	ffffc097          	auipc	ra,0xffffc
    80004804:	486080e7          	jalr	1158(ra) # 80000c86 <release>
}
    80004808:	60e2                	ld	ra,24(sp)
    8000480a:	6442                	ld	s0,16(sp)
    8000480c:	64a2                	ld	s1,8(sp)
    8000480e:	6902                	ld	s2,0(sp)
    80004810:	6105                	add	sp,sp,32
    80004812:	8082                	ret

0000000080004814 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004814:	1101                	add	sp,sp,-32
    80004816:	ec06                	sd	ra,24(sp)
    80004818:	e822                	sd	s0,16(sp)
    8000481a:	e426                	sd	s1,8(sp)
    8000481c:	e04a                	sd	s2,0(sp)
    8000481e:	1000                	add	s0,sp,32
    80004820:	84aa                	mv	s1,a0
    80004822:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004824:	00004597          	auipc	a1,0x4
    80004828:	e7c58593          	add	a1,a1,-388 # 800086a0 <syscalls+0x240>
    8000482c:	0521                	add	a0,a0,8
    8000482e:	ffffc097          	auipc	ra,0xffffc
    80004832:	314080e7          	jalr	788(ra) # 80000b42 <initlock>
  lk->name = name;
    80004836:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000483a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000483e:	0204a423          	sw	zero,40(s1)
}
    80004842:	60e2                	ld	ra,24(sp)
    80004844:	6442                	ld	s0,16(sp)
    80004846:	64a2                	ld	s1,8(sp)
    80004848:	6902                	ld	s2,0(sp)
    8000484a:	6105                	add	sp,sp,32
    8000484c:	8082                	ret

000000008000484e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000484e:	1101                	add	sp,sp,-32
    80004850:	ec06                	sd	ra,24(sp)
    80004852:	e822                	sd	s0,16(sp)
    80004854:	e426                	sd	s1,8(sp)
    80004856:	e04a                	sd	s2,0(sp)
    80004858:	1000                	add	s0,sp,32
    8000485a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000485c:	00850913          	add	s2,a0,8
    80004860:	854a                	mv	a0,s2
    80004862:	ffffc097          	auipc	ra,0xffffc
    80004866:	370080e7          	jalr	880(ra) # 80000bd2 <acquire>
  while (lk->locked) {
    8000486a:	409c                	lw	a5,0(s1)
    8000486c:	cb89                	beqz	a5,8000487e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000486e:	85ca                	mv	a1,s2
    80004870:	8526                	mv	a0,s1
    80004872:	ffffe097          	auipc	ra,0xffffe
    80004876:	9e0080e7          	jalr	-1568(ra) # 80002252 <sleep>
  while (lk->locked) {
    8000487a:	409c                	lw	a5,0(s1)
    8000487c:	fbed                	bnez	a5,8000486e <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000487e:	4785                	li	a5,1
    80004880:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004882:	ffffd097          	auipc	ra,0xffffd
    80004886:	14e080e7          	jalr	334(ra) # 800019d0 <myproc>
    8000488a:	591c                	lw	a5,48(a0)
    8000488c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000488e:	854a                	mv	a0,s2
    80004890:	ffffc097          	auipc	ra,0xffffc
    80004894:	3f6080e7          	jalr	1014(ra) # 80000c86 <release>
}
    80004898:	60e2                	ld	ra,24(sp)
    8000489a:	6442                	ld	s0,16(sp)
    8000489c:	64a2                	ld	s1,8(sp)
    8000489e:	6902                	ld	s2,0(sp)
    800048a0:	6105                	add	sp,sp,32
    800048a2:	8082                	ret

00000000800048a4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800048a4:	1101                	add	sp,sp,-32
    800048a6:	ec06                	sd	ra,24(sp)
    800048a8:	e822                	sd	s0,16(sp)
    800048aa:	e426                	sd	s1,8(sp)
    800048ac:	e04a                	sd	s2,0(sp)
    800048ae:	1000                	add	s0,sp,32
    800048b0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048b2:	00850913          	add	s2,a0,8
    800048b6:	854a                	mv	a0,s2
    800048b8:	ffffc097          	auipc	ra,0xffffc
    800048bc:	31a080e7          	jalr	794(ra) # 80000bd2 <acquire>
  lk->locked = 0;
    800048c0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048c4:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800048c8:	8526                	mv	a0,s1
    800048ca:	ffffe097          	auipc	ra,0xffffe
    800048ce:	9ec080e7          	jalr	-1556(ra) # 800022b6 <wakeup>
  release(&lk->lk);
    800048d2:	854a                	mv	a0,s2
    800048d4:	ffffc097          	auipc	ra,0xffffc
    800048d8:	3b2080e7          	jalr	946(ra) # 80000c86 <release>
}
    800048dc:	60e2                	ld	ra,24(sp)
    800048de:	6442                	ld	s0,16(sp)
    800048e0:	64a2                	ld	s1,8(sp)
    800048e2:	6902                	ld	s2,0(sp)
    800048e4:	6105                	add	sp,sp,32
    800048e6:	8082                	ret

00000000800048e8 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800048e8:	7179                	add	sp,sp,-48
    800048ea:	f406                	sd	ra,40(sp)
    800048ec:	f022                	sd	s0,32(sp)
    800048ee:	ec26                	sd	s1,24(sp)
    800048f0:	e84a                	sd	s2,16(sp)
    800048f2:	e44e                	sd	s3,8(sp)
    800048f4:	1800                	add	s0,sp,48
    800048f6:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800048f8:	00850913          	add	s2,a0,8
    800048fc:	854a                	mv	a0,s2
    800048fe:	ffffc097          	auipc	ra,0xffffc
    80004902:	2d4080e7          	jalr	724(ra) # 80000bd2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004906:	409c                	lw	a5,0(s1)
    80004908:	ef99                	bnez	a5,80004926 <holdingsleep+0x3e>
    8000490a:	4481                	li	s1,0
  release(&lk->lk);
    8000490c:	854a                	mv	a0,s2
    8000490e:	ffffc097          	auipc	ra,0xffffc
    80004912:	378080e7          	jalr	888(ra) # 80000c86 <release>
  return r;
}
    80004916:	8526                	mv	a0,s1
    80004918:	70a2                	ld	ra,40(sp)
    8000491a:	7402                	ld	s0,32(sp)
    8000491c:	64e2                	ld	s1,24(sp)
    8000491e:	6942                	ld	s2,16(sp)
    80004920:	69a2                	ld	s3,8(sp)
    80004922:	6145                	add	sp,sp,48
    80004924:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004926:	0284a983          	lw	s3,40(s1)
    8000492a:	ffffd097          	auipc	ra,0xffffd
    8000492e:	0a6080e7          	jalr	166(ra) # 800019d0 <myproc>
    80004932:	5904                	lw	s1,48(a0)
    80004934:	413484b3          	sub	s1,s1,s3
    80004938:	0014b493          	seqz	s1,s1
    8000493c:	bfc1                	j	8000490c <holdingsleep+0x24>

000000008000493e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000493e:	1141                	add	sp,sp,-16
    80004940:	e406                	sd	ra,8(sp)
    80004942:	e022                	sd	s0,0(sp)
    80004944:	0800                	add	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004946:	00004597          	auipc	a1,0x4
    8000494a:	d6a58593          	add	a1,a1,-662 # 800086b0 <syscalls+0x250>
    8000494e:	0001d517          	auipc	a0,0x1d
    80004952:	b2a50513          	add	a0,a0,-1238 # 80021478 <ftable>
    80004956:	ffffc097          	auipc	ra,0xffffc
    8000495a:	1ec080e7          	jalr	492(ra) # 80000b42 <initlock>
}
    8000495e:	60a2                	ld	ra,8(sp)
    80004960:	6402                	ld	s0,0(sp)
    80004962:	0141                	add	sp,sp,16
    80004964:	8082                	ret

0000000080004966 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004966:	1101                	add	sp,sp,-32
    80004968:	ec06                	sd	ra,24(sp)
    8000496a:	e822                	sd	s0,16(sp)
    8000496c:	e426                	sd	s1,8(sp)
    8000496e:	1000                	add	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004970:	0001d517          	auipc	a0,0x1d
    80004974:	b0850513          	add	a0,a0,-1272 # 80021478 <ftable>
    80004978:	ffffc097          	auipc	ra,0xffffc
    8000497c:	25a080e7          	jalr	602(ra) # 80000bd2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004980:	0001d497          	auipc	s1,0x1d
    80004984:	b1048493          	add	s1,s1,-1264 # 80021490 <ftable+0x18>
    80004988:	0001e717          	auipc	a4,0x1e
    8000498c:	aa870713          	add	a4,a4,-1368 # 80022430 <disk>
    if(f->ref == 0){
    80004990:	40dc                	lw	a5,4(s1)
    80004992:	cf99                	beqz	a5,800049b0 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004994:	02848493          	add	s1,s1,40
    80004998:	fee49ce3          	bne	s1,a4,80004990 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000499c:	0001d517          	auipc	a0,0x1d
    800049a0:	adc50513          	add	a0,a0,-1316 # 80021478 <ftable>
    800049a4:	ffffc097          	auipc	ra,0xffffc
    800049a8:	2e2080e7          	jalr	738(ra) # 80000c86 <release>
  return 0;
    800049ac:	4481                	li	s1,0
    800049ae:	a819                	j	800049c4 <filealloc+0x5e>
      f->ref = 1;
    800049b0:	4785                	li	a5,1
    800049b2:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800049b4:	0001d517          	auipc	a0,0x1d
    800049b8:	ac450513          	add	a0,a0,-1340 # 80021478 <ftable>
    800049bc:	ffffc097          	auipc	ra,0xffffc
    800049c0:	2ca080e7          	jalr	714(ra) # 80000c86 <release>
}
    800049c4:	8526                	mv	a0,s1
    800049c6:	60e2                	ld	ra,24(sp)
    800049c8:	6442                	ld	s0,16(sp)
    800049ca:	64a2                	ld	s1,8(sp)
    800049cc:	6105                	add	sp,sp,32
    800049ce:	8082                	ret

00000000800049d0 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800049d0:	1101                	add	sp,sp,-32
    800049d2:	ec06                	sd	ra,24(sp)
    800049d4:	e822                	sd	s0,16(sp)
    800049d6:	e426                	sd	s1,8(sp)
    800049d8:	1000                	add	s0,sp,32
    800049da:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800049dc:	0001d517          	auipc	a0,0x1d
    800049e0:	a9c50513          	add	a0,a0,-1380 # 80021478 <ftable>
    800049e4:	ffffc097          	auipc	ra,0xffffc
    800049e8:	1ee080e7          	jalr	494(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    800049ec:	40dc                	lw	a5,4(s1)
    800049ee:	02f05263          	blez	a5,80004a12 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800049f2:	2785                	addw	a5,a5,1
    800049f4:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800049f6:	0001d517          	auipc	a0,0x1d
    800049fa:	a8250513          	add	a0,a0,-1406 # 80021478 <ftable>
    800049fe:	ffffc097          	auipc	ra,0xffffc
    80004a02:	288080e7          	jalr	648(ra) # 80000c86 <release>
  return f;
}
    80004a06:	8526                	mv	a0,s1
    80004a08:	60e2                	ld	ra,24(sp)
    80004a0a:	6442                	ld	s0,16(sp)
    80004a0c:	64a2                	ld	s1,8(sp)
    80004a0e:	6105                	add	sp,sp,32
    80004a10:	8082                	ret
    panic("filedup");
    80004a12:	00004517          	auipc	a0,0x4
    80004a16:	ca650513          	add	a0,a0,-858 # 800086b8 <syscalls+0x258>
    80004a1a:	ffffc097          	auipc	ra,0xffffc
    80004a1e:	b22080e7          	jalr	-1246(ra) # 8000053c <panic>

0000000080004a22 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004a22:	7139                	add	sp,sp,-64
    80004a24:	fc06                	sd	ra,56(sp)
    80004a26:	f822                	sd	s0,48(sp)
    80004a28:	f426                	sd	s1,40(sp)
    80004a2a:	f04a                	sd	s2,32(sp)
    80004a2c:	ec4e                	sd	s3,24(sp)
    80004a2e:	e852                	sd	s4,16(sp)
    80004a30:	e456                	sd	s5,8(sp)
    80004a32:	0080                	add	s0,sp,64
    80004a34:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004a36:	0001d517          	auipc	a0,0x1d
    80004a3a:	a4250513          	add	a0,a0,-1470 # 80021478 <ftable>
    80004a3e:	ffffc097          	auipc	ra,0xffffc
    80004a42:	194080e7          	jalr	404(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    80004a46:	40dc                	lw	a5,4(s1)
    80004a48:	06f05163          	blez	a5,80004aaa <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004a4c:	37fd                	addw	a5,a5,-1
    80004a4e:	0007871b          	sext.w	a4,a5
    80004a52:	c0dc                	sw	a5,4(s1)
    80004a54:	06e04363          	bgtz	a4,80004aba <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004a58:	0004a903          	lw	s2,0(s1)
    80004a5c:	0094ca83          	lbu	s5,9(s1)
    80004a60:	0104ba03          	ld	s4,16(s1)
    80004a64:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004a68:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004a6c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004a70:	0001d517          	auipc	a0,0x1d
    80004a74:	a0850513          	add	a0,a0,-1528 # 80021478 <ftable>
    80004a78:	ffffc097          	auipc	ra,0xffffc
    80004a7c:	20e080e7          	jalr	526(ra) # 80000c86 <release>

  if(ff.type == FD_PIPE){
    80004a80:	4785                	li	a5,1
    80004a82:	04f90d63          	beq	s2,a5,80004adc <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004a86:	3979                	addw	s2,s2,-2
    80004a88:	4785                	li	a5,1
    80004a8a:	0527e063          	bltu	a5,s2,80004aca <fileclose+0xa8>
    begin_op();
    80004a8e:	00000097          	auipc	ra,0x0
    80004a92:	ad0080e7          	jalr	-1328(ra) # 8000455e <begin_op>
    iput(ff.ip);
    80004a96:	854e                	mv	a0,s3
    80004a98:	fffff097          	auipc	ra,0xfffff
    80004a9c:	2da080e7          	jalr	730(ra) # 80003d72 <iput>
    end_op();
    80004aa0:	00000097          	auipc	ra,0x0
    80004aa4:	b38080e7          	jalr	-1224(ra) # 800045d8 <end_op>
    80004aa8:	a00d                	j	80004aca <fileclose+0xa8>
    panic("fileclose");
    80004aaa:	00004517          	auipc	a0,0x4
    80004aae:	c1650513          	add	a0,a0,-1002 # 800086c0 <syscalls+0x260>
    80004ab2:	ffffc097          	auipc	ra,0xffffc
    80004ab6:	a8a080e7          	jalr	-1398(ra) # 8000053c <panic>
    release(&ftable.lock);
    80004aba:	0001d517          	auipc	a0,0x1d
    80004abe:	9be50513          	add	a0,a0,-1602 # 80021478 <ftable>
    80004ac2:	ffffc097          	auipc	ra,0xffffc
    80004ac6:	1c4080e7          	jalr	452(ra) # 80000c86 <release>
  }
}
    80004aca:	70e2                	ld	ra,56(sp)
    80004acc:	7442                	ld	s0,48(sp)
    80004ace:	74a2                	ld	s1,40(sp)
    80004ad0:	7902                	ld	s2,32(sp)
    80004ad2:	69e2                	ld	s3,24(sp)
    80004ad4:	6a42                	ld	s4,16(sp)
    80004ad6:	6aa2                	ld	s5,8(sp)
    80004ad8:	6121                	add	sp,sp,64
    80004ada:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004adc:	85d6                	mv	a1,s5
    80004ade:	8552                	mv	a0,s4
    80004ae0:	00000097          	auipc	ra,0x0
    80004ae4:	348080e7          	jalr	840(ra) # 80004e28 <pipeclose>
    80004ae8:	b7cd                	j	80004aca <fileclose+0xa8>

0000000080004aea <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004aea:	715d                	add	sp,sp,-80
    80004aec:	e486                	sd	ra,72(sp)
    80004aee:	e0a2                	sd	s0,64(sp)
    80004af0:	fc26                	sd	s1,56(sp)
    80004af2:	f84a                	sd	s2,48(sp)
    80004af4:	f44e                	sd	s3,40(sp)
    80004af6:	0880                	add	s0,sp,80
    80004af8:	84aa                	mv	s1,a0
    80004afa:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004afc:	ffffd097          	auipc	ra,0xffffd
    80004b00:	ed4080e7          	jalr	-300(ra) # 800019d0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004b04:	409c                	lw	a5,0(s1)
    80004b06:	37f9                	addw	a5,a5,-2
    80004b08:	4705                	li	a4,1
    80004b0a:	04f76763          	bltu	a4,a5,80004b58 <filestat+0x6e>
    80004b0e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004b10:	6c88                	ld	a0,24(s1)
    80004b12:	fffff097          	auipc	ra,0xfffff
    80004b16:	0a6080e7          	jalr	166(ra) # 80003bb8 <ilock>
    stati(f->ip, &st);
    80004b1a:	fb840593          	add	a1,s0,-72
    80004b1e:	6c88                	ld	a0,24(s1)
    80004b20:	fffff097          	auipc	ra,0xfffff
    80004b24:	322080e7          	jalr	802(ra) # 80003e42 <stati>
    iunlock(f->ip);
    80004b28:	6c88                	ld	a0,24(s1)
    80004b2a:	fffff097          	auipc	ra,0xfffff
    80004b2e:	150080e7          	jalr	336(ra) # 80003c7a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004b32:	46e1                	li	a3,24
    80004b34:	fb840613          	add	a2,s0,-72
    80004b38:	85ce                	mv	a1,s3
    80004b3a:	05093503          	ld	a0,80(s2)
    80004b3e:	ffffd097          	auipc	ra,0xffffd
    80004b42:	ae2080e7          	jalr	-1310(ra) # 80001620 <copyout>
    80004b46:	41f5551b          	sraw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004b4a:	60a6                	ld	ra,72(sp)
    80004b4c:	6406                	ld	s0,64(sp)
    80004b4e:	74e2                	ld	s1,56(sp)
    80004b50:	7942                	ld	s2,48(sp)
    80004b52:	79a2                	ld	s3,40(sp)
    80004b54:	6161                	add	sp,sp,80
    80004b56:	8082                	ret
  return -1;
    80004b58:	557d                	li	a0,-1
    80004b5a:	bfc5                	j	80004b4a <filestat+0x60>

0000000080004b5c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004b5c:	7179                	add	sp,sp,-48
    80004b5e:	f406                	sd	ra,40(sp)
    80004b60:	f022                	sd	s0,32(sp)
    80004b62:	ec26                	sd	s1,24(sp)
    80004b64:	e84a                	sd	s2,16(sp)
    80004b66:	e44e                	sd	s3,8(sp)
    80004b68:	1800                	add	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004b6a:	00854783          	lbu	a5,8(a0)
    80004b6e:	c3d5                	beqz	a5,80004c12 <fileread+0xb6>
    80004b70:	84aa                	mv	s1,a0
    80004b72:	89ae                	mv	s3,a1
    80004b74:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b76:	411c                	lw	a5,0(a0)
    80004b78:	4705                	li	a4,1
    80004b7a:	04e78963          	beq	a5,a4,80004bcc <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b7e:	470d                	li	a4,3
    80004b80:	04e78d63          	beq	a5,a4,80004bda <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b84:	4709                	li	a4,2
    80004b86:	06e79e63          	bne	a5,a4,80004c02 <fileread+0xa6>
    ilock(f->ip);
    80004b8a:	6d08                	ld	a0,24(a0)
    80004b8c:	fffff097          	auipc	ra,0xfffff
    80004b90:	02c080e7          	jalr	44(ra) # 80003bb8 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004b94:	874a                	mv	a4,s2
    80004b96:	5094                	lw	a3,32(s1)
    80004b98:	864e                	mv	a2,s3
    80004b9a:	4585                	li	a1,1
    80004b9c:	6c88                	ld	a0,24(s1)
    80004b9e:	fffff097          	auipc	ra,0xfffff
    80004ba2:	2ce080e7          	jalr	718(ra) # 80003e6c <readi>
    80004ba6:	892a                	mv	s2,a0
    80004ba8:	00a05563          	blez	a0,80004bb2 <fileread+0x56>
      f->off += r;
    80004bac:	509c                	lw	a5,32(s1)
    80004bae:	9fa9                	addw	a5,a5,a0
    80004bb0:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004bb2:	6c88                	ld	a0,24(s1)
    80004bb4:	fffff097          	auipc	ra,0xfffff
    80004bb8:	0c6080e7          	jalr	198(ra) # 80003c7a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004bbc:	854a                	mv	a0,s2
    80004bbe:	70a2                	ld	ra,40(sp)
    80004bc0:	7402                	ld	s0,32(sp)
    80004bc2:	64e2                	ld	s1,24(sp)
    80004bc4:	6942                	ld	s2,16(sp)
    80004bc6:	69a2                	ld	s3,8(sp)
    80004bc8:	6145                	add	sp,sp,48
    80004bca:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004bcc:	6908                	ld	a0,16(a0)
    80004bce:	00000097          	auipc	ra,0x0
    80004bd2:	3c2080e7          	jalr	962(ra) # 80004f90 <piperead>
    80004bd6:	892a                	mv	s2,a0
    80004bd8:	b7d5                	j	80004bbc <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004bda:	02451783          	lh	a5,36(a0)
    80004bde:	03079693          	sll	a3,a5,0x30
    80004be2:	92c1                	srl	a3,a3,0x30
    80004be4:	4725                	li	a4,9
    80004be6:	02d76863          	bltu	a4,a3,80004c16 <fileread+0xba>
    80004bea:	0792                	sll	a5,a5,0x4
    80004bec:	0001c717          	auipc	a4,0x1c
    80004bf0:	7ec70713          	add	a4,a4,2028 # 800213d8 <devsw>
    80004bf4:	97ba                	add	a5,a5,a4
    80004bf6:	639c                	ld	a5,0(a5)
    80004bf8:	c38d                	beqz	a5,80004c1a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004bfa:	4505                	li	a0,1
    80004bfc:	9782                	jalr	a5
    80004bfe:	892a                	mv	s2,a0
    80004c00:	bf75                	j	80004bbc <fileread+0x60>
    panic("fileread");
    80004c02:	00004517          	auipc	a0,0x4
    80004c06:	ace50513          	add	a0,a0,-1330 # 800086d0 <syscalls+0x270>
    80004c0a:	ffffc097          	auipc	ra,0xffffc
    80004c0e:	932080e7          	jalr	-1742(ra) # 8000053c <panic>
    return -1;
    80004c12:	597d                	li	s2,-1
    80004c14:	b765                	j	80004bbc <fileread+0x60>
      return -1;
    80004c16:	597d                	li	s2,-1
    80004c18:	b755                	j	80004bbc <fileread+0x60>
    80004c1a:	597d                	li	s2,-1
    80004c1c:	b745                	j	80004bbc <fileread+0x60>

0000000080004c1e <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004c1e:	00954783          	lbu	a5,9(a0)
    80004c22:	10078e63          	beqz	a5,80004d3e <filewrite+0x120>
{
    80004c26:	715d                	add	sp,sp,-80
    80004c28:	e486                	sd	ra,72(sp)
    80004c2a:	e0a2                	sd	s0,64(sp)
    80004c2c:	fc26                	sd	s1,56(sp)
    80004c2e:	f84a                	sd	s2,48(sp)
    80004c30:	f44e                	sd	s3,40(sp)
    80004c32:	f052                	sd	s4,32(sp)
    80004c34:	ec56                	sd	s5,24(sp)
    80004c36:	e85a                	sd	s6,16(sp)
    80004c38:	e45e                	sd	s7,8(sp)
    80004c3a:	e062                	sd	s8,0(sp)
    80004c3c:	0880                	add	s0,sp,80
    80004c3e:	892a                	mv	s2,a0
    80004c40:	8b2e                	mv	s6,a1
    80004c42:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c44:	411c                	lw	a5,0(a0)
    80004c46:	4705                	li	a4,1
    80004c48:	02e78263          	beq	a5,a4,80004c6c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c4c:	470d                	li	a4,3
    80004c4e:	02e78563          	beq	a5,a4,80004c78 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c52:	4709                	li	a4,2
    80004c54:	0ce79d63          	bne	a5,a4,80004d2e <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004c58:	0ac05b63          	blez	a2,80004d0e <filewrite+0xf0>
    int i = 0;
    80004c5c:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004c5e:	6b85                	lui	s7,0x1
    80004c60:	c00b8b93          	add	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004c64:	6c05                	lui	s8,0x1
    80004c66:	c00c0c1b          	addw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004c6a:	a851                	j	80004cfe <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004c6c:	6908                	ld	a0,16(a0)
    80004c6e:	00000097          	auipc	ra,0x0
    80004c72:	22a080e7          	jalr	554(ra) # 80004e98 <pipewrite>
    80004c76:	a045                	j	80004d16 <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c78:	02451783          	lh	a5,36(a0)
    80004c7c:	03079693          	sll	a3,a5,0x30
    80004c80:	92c1                	srl	a3,a3,0x30
    80004c82:	4725                	li	a4,9
    80004c84:	0ad76f63          	bltu	a4,a3,80004d42 <filewrite+0x124>
    80004c88:	0792                	sll	a5,a5,0x4
    80004c8a:	0001c717          	auipc	a4,0x1c
    80004c8e:	74e70713          	add	a4,a4,1870 # 800213d8 <devsw>
    80004c92:	97ba                	add	a5,a5,a4
    80004c94:	679c                	ld	a5,8(a5)
    80004c96:	cbc5                	beqz	a5,80004d46 <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004c98:	4505                	li	a0,1
    80004c9a:	9782                	jalr	a5
    80004c9c:	a8ad                	j	80004d16 <filewrite+0xf8>
      if(n1 > max)
    80004c9e:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004ca2:	00000097          	auipc	ra,0x0
    80004ca6:	8bc080e7          	jalr	-1860(ra) # 8000455e <begin_op>
      ilock(f->ip);
    80004caa:	01893503          	ld	a0,24(s2)
    80004cae:	fffff097          	auipc	ra,0xfffff
    80004cb2:	f0a080e7          	jalr	-246(ra) # 80003bb8 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004cb6:	8756                	mv	a4,s5
    80004cb8:	02092683          	lw	a3,32(s2)
    80004cbc:	01698633          	add	a2,s3,s6
    80004cc0:	4585                	li	a1,1
    80004cc2:	01893503          	ld	a0,24(s2)
    80004cc6:	fffff097          	auipc	ra,0xfffff
    80004cca:	29e080e7          	jalr	670(ra) # 80003f64 <writei>
    80004cce:	84aa                	mv	s1,a0
    80004cd0:	00a05763          	blez	a0,80004cde <filewrite+0xc0>
        f->off += r;
    80004cd4:	02092783          	lw	a5,32(s2)
    80004cd8:	9fa9                	addw	a5,a5,a0
    80004cda:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004cde:	01893503          	ld	a0,24(s2)
    80004ce2:	fffff097          	auipc	ra,0xfffff
    80004ce6:	f98080e7          	jalr	-104(ra) # 80003c7a <iunlock>
      end_op();
    80004cea:	00000097          	auipc	ra,0x0
    80004cee:	8ee080e7          	jalr	-1810(ra) # 800045d8 <end_op>

      if(r != n1){
    80004cf2:	009a9f63          	bne	s5,s1,80004d10 <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004cf6:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004cfa:	0149db63          	bge	s3,s4,80004d10 <filewrite+0xf2>
      int n1 = n - i;
    80004cfe:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004d02:	0004879b          	sext.w	a5,s1
    80004d06:	f8fbdce3          	bge	s7,a5,80004c9e <filewrite+0x80>
    80004d0a:	84e2                	mv	s1,s8
    80004d0c:	bf49                	j	80004c9e <filewrite+0x80>
    int i = 0;
    80004d0e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004d10:	033a1d63          	bne	s4,s3,80004d4a <filewrite+0x12c>
    80004d14:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004d16:	60a6                	ld	ra,72(sp)
    80004d18:	6406                	ld	s0,64(sp)
    80004d1a:	74e2                	ld	s1,56(sp)
    80004d1c:	7942                	ld	s2,48(sp)
    80004d1e:	79a2                	ld	s3,40(sp)
    80004d20:	7a02                	ld	s4,32(sp)
    80004d22:	6ae2                	ld	s5,24(sp)
    80004d24:	6b42                	ld	s6,16(sp)
    80004d26:	6ba2                	ld	s7,8(sp)
    80004d28:	6c02                	ld	s8,0(sp)
    80004d2a:	6161                	add	sp,sp,80
    80004d2c:	8082                	ret
    panic("filewrite");
    80004d2e:	00004517          	auipc	a0,0x4
    80004d32:	9b250513          	add	a0,a0,-1614 # 800086e0 <syscalls+0x280>
    80004d36:	ffffc097          	auipc	ra,0xffffc
    80004d3a:	806080e7          	jalr	-2042(ra) # 8000053c <panic>
    return -1;
    80004d3e:	557d                	li	a0,-1
}
    80004d40:	8082                	ret
      return -1;
    80004d42:	557d                	li	a0,-1
    80004d44:	bfc9                	j	80004d16 <filewrite+0xf8>
    80004d46:	557d                	li	a0,-1
    80004d48:	b7f9                	j	80004d16 <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80004d4a:	557d                	li	a0,-1
    80004d4c:	b7e9                	j	80004d16 <filewrite+0xf8>

0000000080004d4e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004d4e:	7179                	add	sp,sp,-48
    80004d50:	f406                	sd	ra,40(sp)
    80004d52:	f022                	sd	s0,32(sp)
    80004d54:	ec26                	sd	s1,24(sp)
    80004d56:	e84a                	sd	s2,16(sp)
    80004d58:	e44e                	sd	s3,8(sp)
    80004d5a:	e052                	sd	s4,0(sp)
    80004d5c:	1800                	add	s0,sp,48
    80004d5e:	84aa                	mv	s1,a0
    80004d60:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004d62:	0005b023          	sd	zero,0(a1)
    80004d66:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004d6a:	00000097          	auipc	ra,0x0
    80004d6e:	bfc080e7          	jalr	-1028(ra) # 80004966 <filealloc>
    80004d72:	e088                	sd	a0,0(s1)
    80004d74:	c551                	beqz	a0,80004e00 <pipealloc+0xb2>
    80004d76:	00000097          	auipc	ra,0x0
    80004d7a:	bf0080e7          	jalr	-1040(ra) # 80004966 <filealloc>
    80004d7e:	00aa3023          	sd	a0,0(s4)
    80004d82:	c92d                	beqz	a0,80004df4 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004d84:	ffffc097          	auipc	ra,0xffffc
    80004d88:	d5e080e7          	jalr	-674(ra) # 80000ae2 <kalloc>
    80004d8c:	892a                	mv	s2,a0
    80004d8e:	c125                	beqz	a0,80004dee <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004d90:	4985                	li	s3,1
    80004d92:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004d96:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004d9a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004d9e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004da2:	00004597          	auipc	a1,0x4
    80004da6:	94e58593          	add	a1,a1,-1714 # 800086f0 <syscalls+0x290>
    80004daa:	ffffc097          	auipc	ra,0xffffc
    80004dae:	d98080e7          	jalr	-616(ra) # 80000b42 <initlock>
  (*f0)->type = FD_PIPE;
    80004db2:	609c                	ld	a5,0(s1)
    80004db4:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004db8:	609c                	ld	a5,0(s1)
    80004dba:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004dbe:	609c                	ld	a5,0(s1)
    80004dc0:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004dc4:	609c                	ld	a5,0(s1)
    80004dc6:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004dca:	000a3783          	ld	a5,0(s4)
    80004dce:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004dd2:	000a3783          	ld	a5,0(s4)
    80004dd6:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004dda:	000a3783          	ld	a5,0(s4)
    80004dde:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004de2:	000a3783          	ld	a5,0(s4)
    80004de6:	0127b823          	sd	s2,16(a5)
  return 0;
    80004dea:	4501                	li	a0,0
    80004dec:	a025                	j	80004e14 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004dee:	6088                	ld	a0,0(s1)
    80004df0:	e501                	bnez	a0,80004df8 <pipealloc+0xaa>
    80004df2:	a039                	j	80004e00 <pipealloc+0xb2>
    80004df4:	6088                	ld	a0,0(s1)
    80004df6:	c51d                	beqz	a0,80004e24 <pipealloc+0xd6>
    fileclose(*f0);
    80004df8:	00000097          	auipc	ra,0x0
    80004dfc:	c2a080e7          	jalr	-982(ra) # 80004a22 <fileclose>
  if(*f1)
    80004e00:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e04:	557d                	li	a0,-1
  if(*f1)
    80004e06:	c799                	beqz	a5,80004e14 <pipealloc+0xc6>
    fileclose(*f1);
    80004e08:	853e                	mv	a0,a5
    80004e0a:	00000097          	auipc	ra,0x0
    80004e0e:	c18080e7          	jalr	-1000(ra) # 80004a22 <fileclose>
  return -1;
    80004e12:	557d                	li	a0,-1
}
    80004e14:	70a2                	ld	ra,40(sp)
    80004e16:	7402                	ld	s0,32(sp)
    80004e18:	64e2                	ld	s1,24(sp)
    80004e1a:	6942                	ld	s2,16(sp)
    80004e1c:	69a2                	ld	s3,8(sp)
    80004e1e:	6a02                	ld	s4,0(sp)
    80004e20:	6145                	add	sp,sp,48
    80004e22:	8082                	ret
  return -1;
    80004e24:	557d                	li	a0,-1
    80004e26:	b7fd                	j	80004e14 <pipealloc+0xc6>

0000000080004e28 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004e28:	1101                	add	sp,sp,-32
    80004e2a:	ec06                	sd	ra,24(sp)
    80004e2c:	e822                	sd	s0,16(sp)
    80004e2e:	e426                	sd	s1,8(sp)
    80004e30:	e04a                	sd	s2,0(sp)
    80004e32:	1000                	add	s0,sp,32
    80004e34:	84aa                	mv	s1,a0
    80004e36:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004e38:	ffffc097          	auipc	ra,0xffffc
    80004e3c:	d9a080e7          	jalr	-614(ra) # 80000bd2 <acquire>
  if(writable){
    80004e40:	02090d63          	beqz	s2,80004e7a <pipeclose+0x52>
    pi->writeopen = 0;
    80004e44:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004e48:	21848513          	add	a0,s1,536
    80004e4c:	ffffd097          	auipc	ra,0xffffd
    80004e50:	46a080e7          	jalr	1130(ra) # 800022b6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004e54:	2204b783          	ld	a5,544(s1)
    80004e58:	eb95                	bnez	a5,80004e8c <pipeclose+0x64>
    release(&pi->lock);
    80004e5a:	8526                	mv	a0,s1
    80004e5c:	ffffc097          	auipc	ra,0xffffc
    80004e60:	e2a080e7          	jalr	-470(ra) # 80000c86 <release>
    kfree((char*)pi);
    80004e64:	8526                	mv	a0,s1
    80004e66:	ffffc097          	auipc	ra,0xffffc
    80004e6a:	b7e080e7          	jalr	-1154(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    80004e6e:	60e2                	ld	ra,24(sp)
    80004e70:	6442                	ld	s0,16(sp)
    80004e72:	64a2                	ld	s1,8(sp)
    80004e74:	6902                	ld	s2,0(sp)
    80004e76:	6105                	add	sp,sp,32
    80004e78:	8082                	ret
    pi->readopen = 0;
    80004e7a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004e7e:	21c48513          	add	a0,s1,540
    80004e82:	ffffd097          	auipc	ra,0xffffd
    80004e86:	434080e7          	jalr	1076(ra) # 800022b6 <wakeup>
    80004e8a:	b7e9                	j	80004e54 <pipeclose+0x2c>
    release(&pi->lock);
    80004e8c:	8526                	mv	a0,s1
    80004e8e:	ffffc097          	auipc	ra,0xffffc
    80004e92:	df8080e7          	jalr	-520(ra) # 80000c86 <release>
}
    80004e96:	bfe1                	j	80004e6e <pipeclose+0x46>

0000000080004e98 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004e98:	711d                	add	sp,sp,-96
    80004e9a:	ec86                	sd	ra,88(sp)
    80004e9c:	e8a2                	sd	s0,80(sp)
    80004e9e:	e4a6                	sd	s1,72(sp)
    80004ea0:	e0ca                	sd	s2,64(sp)
    80004ea2:	fc4e                	sd	s3,56(sp)
    80004ea4:	f852                	sd	s4,48(sp)
    80004ea6:	f456                	sd	s5,40(sp)
    80004ea8:	f05a                	sd	s6,32(sp)
    80004eaa:	ec5e                	sd	s7,24(sp)
    80004eac:	e862                	sd	s8,16(sp)
    80004eae:	1080                	add	s0,sp,96
    80004eb0:	84aa                	mv	s1,a0
    80004eb2:	8aae                	mv	s5,a1
    80004eb4:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004eb6:	ffffd097          	auipc	ra,0xffffd
    80004eba:	b1a080e7          	jalr	-1254(ra) # 800019d0 <myproc>
    80004ebe:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004ec0:	8526                	mv	a0,s1
    80004ec2:	ffffc097          	auipc	ra,0xffffc
    80004ec6:	d10080e7          	jalr	-752(ra) # 80000bd2 <acquire>
  while(i < n){
    80004eca:	0b405663          	blez	s4,80004f76 <pipewrite+0xde>
  int i = 0;
    80004ece:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ed0:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004ed2:	21848c13          	add	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ed6:	21c48b93          	add	s7,s1,540
    80004eda:	a089                	j	80004f1c <pipewrite+0x84>
      release(&pi->lock);
    80004edc:	8526                	mv	a0,s1
    80004ede:	ffffc097          	auipc	ra,0xffffc
    80004ee2:	da8080e7          	jalr	-600(ra) # 80000c86 <release>
      return -1;
    80004ee6:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004ee8:	854a                	mv	a0,s2
    80004eea:	60e6                	ld	ra,88(sp)
    80004eec:	6446                	ld	s0,80(sp)
    80004eee:	64a6                	ld	s1,72(sp)
    80004ef0:	6906                	ld	s2,64(sp)
    80004ef2:	79e2                	ld	s3,56(sp)
    80004ef4:	7a42                	ld	s4,48(sp)
    80004ef6:	7aa2                	ld	s5,40(sp)
    80004ef8:	7b02                	ld	s6,32(sp)
    80004efa:	6be2                	ld	s7,24(sp)
    80004efc:	6c42                	ld	s8,16(sp)
    80004efe:	6125                	add	sp,sp,96
    80004f00:	8082                	ret
      wakeup(&pi->nread);
    80004f02:	8562                	mv	a0,s8
    80004f04:	ffffd097          	auipc	ra,0xffffd
    80004f08:	3b2080e7          	jalr	946(ra) # 800022b6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004f0c:	85a6                	mv	a1,s1
    80004f0e:	855e                	mv	a0,s7
    80004f10:	ffffd097          	auipc	ra,0xffffd
    80004f14:	342080e7          	jalr	834(ra) # 80002252 <sleep>
  while(i < n){
    80004f18:	07495063          	bge	s2,s4,80004f78 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004f1c:	2204a783          	lw	a5,544(s1)
    80004f20:	dfd5                	beqz	a5,80004edc <pipewrite+0x44>
    80004f22:	854e                	mv	a0,s3
    80004f24:	ffffd097          	auipc	ra,0xffffd
    80004f28:	5e2080e7          	jalr	1506(ra) # 80002506 <killed>
    80004f2c:	f945                	bnez	a0,80004edc <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004f2e:	2184a783          	lw	a5,536(s1)
    80004f32:	21c4a703          	lw	a4,540(s1)
    80004f36:	2007879b          	addw	a5,a5,512
    80004f3a:	fcf704e3          	beq	a4,a5,80004f02 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f3e:	4685                	li	a3,1
    80004f40:	01590633          	add	a2,s2,s5
    80004f44:	faf40593          	add	a1,s0,-81
    80004f48:	0509b503          	ld	a0,80(s3)
    80004f4c:	ffffc097          	auipc	ra,0xffffc
    80004f50:	7d0080e7          	jalr	2000(ra) # 8000171c <copyin>
    80004f54:	03650263          	beq	a0,s6,80004f78 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f58:	21c4a783          	lw	a5,540(s1)
    80004f5c:	0017871b          	addw	a4,a5,1
    80004f60:	20e4ae23          	sw	a4,540(s1)
    80004f64:	1ff7f793          	and	a5,a5,511
    80004f68:	97a6                	add	a5,a5,s1
    80004f6a:	faf44703          	lbu	a4,-81(s0)
    80004f6e:	00e78c23          	sb	a4,24(a5)
      i++;
    80004f72:	2905                	addw	s2,s2,1
    80004f74:	b755                	j	80004f18 <pipewrite+0x80>
  int i = 0;
    80004f76:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004f78:	21848513          	add	a0,s1,536
    80004f7c:	ffffd097          	auipc	ra,0xffffd
    80004f80:	33a080e7          	jalr	826(ra) # 800022b6 <wakeup>
  release(&pi->lock);
    80004f84:	8526                	mv	a0,s1
    80004f86:	ffffc097          	auipc	ra,0xffffc
    80004f8a:	d00080e7          	jalr	-768(ra) # 80000c86 <release>
  return i;
    80004f8e:	bfa9                	j	80004ee8 <pipewrite+0x50>

0000000080004f90 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004f90:	715d                	add	sp,sp,-80
    80004f92:	e486                	sd	ra,72(sp)
    80004f94:	e0a2                	sd	s0,64(sp)
    80004f96:	fc26                	sd	s1,56(sp)
    80004f98:	f84a                	sd	s2,48(sp)
    80004f9a:	f44e                	sd	s3,40(sp)
    80004f9c:	f052                	sd	s4,32(sp)
    80004f9e:	ec56                	sd	s5,24(sp)
    80004fa0:	e85a                	sd	s6,16(sp)
    80004fa2:	0880                	add	s0,sp,80
    80004fa4:	84aa                	mv	s1,a0
    80004fa6:	892e                	mv	s2,a1
    80004fa8:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004faa:	ffffd097          	auipc	ra,0xffffd
    80004fae:	a26080e7          	jalr	-1498(ra) # 800019d0 <myproc>
    80004fb2:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004fb4:	8526                	mv	a0,s1
    80004fb6:	ffffc097          	auipc	ra,0xffffc
    80004fba:	c1c080e7          	jalr	-996(ra) # 80000bd2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fbe:	2184a703          	lw	a4,536(s1)
    80004fc2:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004fc6:	21848993          	add	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fca:	02f71763          	bne	a4,a5,80004ff8 <piperead+0x68>
    80004fce:	2244a783          	lw	a5,548(s1)
    80004fd2:	c39d                	beqz	a5,80004ff8 <piperead+0x68>
    if(killed(pr)){
    80004fd4:	8552                	mv	a0,s4
    80004fd6:	ffffd097          	auipc	ra,0xffffd
    80004fda:	530080e7          	jalr	1328(ra) # 80002506 <killed>
    80004fde:	e949                	bnez	a0,80005070 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004fe0:	85a6                	mv	a1,s1
    80004fe2:	854e                	mv	a0,s3
    80004fe4:	ffffd097          	auipc	ra,0xffffd
    80004fe8:	26e080e7          	jalr	622(ra) # 80002252 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fec:	2184a703          	lw	a4,536(s1)
    80004ff0:	21c4a783          	lw	a5,540(s1)
    80004ff4:	fcf70de3          	beq	a4,a5,80004fce <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ff8:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ffa:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ffc:	05505463          	blez	s5,80005044 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80005000:	2184a783          	lw	a5,536(s1)
    80005004:	21c4a703          	lw	a4,540(s1)
    80005008:	02f70e63          	beq	a4,a5,80005044 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000500c:	0017871b          	addw	a4,a5,1
    80005010:	20e4ac23          	sw	a4,536(s1)
    80005014:	1ff7f793          	and	a5,a5,511
    80005018:	97a6                	add	a5,a5,s1
    8000501a:	0187c783          	lbu	a5,24(a5)
    8000501e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005022:	4685                	li	a3,1
    80005024:	fbf40613          	add	a2,s0,-65
    80005028:	85ca                	mv	a1,s2
    8000502a:	050a3503          	ld	a0,80(s4)
    8000502e:	ffffc097          	auipc	ra,0xffffc
    80005032:	5f2080e7          	jalr	1522(ra) # 80001620 <copyout>
    80005036:	01650763          	beq	a0,s6,80005044 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000503a:	2985                	addw	s3,s3,1
    8000503c:	0905                	add	s2,s2,1
    8000503e:	fd3a91e3          	bne	s5,s3,80005000 <piperead+0x70>
    80005042:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005044:	21c48513          	add	a0,s1,540
    80005048:	ffffd097          	auipc	ra,0xffffd
    8000504c:	26e080e7          	jalr	622(ra) # 800022b6 <wakeup>
  release(&pi->lock);
    80005050:	8526                	mv	a0,s1
    80005052:	ffffc097          	auipc	ra,0xffffc
    80005056:	c34080e7          	jalr	-972(ra) # 80000c86 <release>
  return i;
}
    8000505a:	854e                	mv	a0,s3
    8000505c:	60a6                	ld	ra,72(sp)
    8000505e:	6406                	ld	s0,64(sp)
    80005060:	74e2                	ld	s1,56(sp)
    80005062:	7942                	ld	s2,48(sp)
    80005064:	79a2                	ld	s3,40(sp)
    80005066:	7a02                	ld	s4,32(sp)
    80005068:	6ae2                	ld	s5,24(sp)
    8000506a:	6b42                	ld	s6,16(sp)
    8000506c:	6161                	add	sp,sp,80
    8000506e:	8082                	ret
      release(&pi->lock);
    80005070:	8526                	mv	a0,s1
    80005072:	ffffc097          	auipc	ra,0xffffc
    80005076:	c14080e7          	jalr	-1004(ra) # 80000c86 <release>
      return -1;
    8000507a:	59fd                	li	s3,-1
    8000507c:	bff9                	j	8000505a <piperead+0xca>

000000008000507e <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    8000507e:	1141                	add	sp,sp,-16
    80005080:	e422                	sd	s0,8(sp)
    80005082:	0800                	add	s0,sp,16
    80005084:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005086:	8905                	and	a0,a0,1
    80005088:	050e                	sll	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    8000508a:	8b89                	and	a5,a5,2
    8000508c:	c399                	beqz	a5,80005092 <flags2perm+0x14>
      perm |= PTE_W;
    8000508e:	00456513          	or	a0,a0,4
    return perm;
}
    80005092:	6422                	ld	s0,8(sp)
    80005094:	0141                	add	sp,sp,16
    80005096:	8082                	ret

0000000080005098 <exec>:

int
exec(char *path, char **argv)
{
    80005098:	df010113          	add	sp,sp,-528
    8000509c:	20113423          	sd	ra,520(sp)
    800050a0:	20813023          	sd	s0,512(sp)
    800050a4:	ffa6                	sd	s1,504(sp)
    800050a6:	fbca                	sd	s2,496(sp)
    800050a8:	f7ce                	sd	s3,488(sp)
    800050aa:	f3d2                	sd	s4,480(sp)
    800050ac:	efd6                	sd	s5,472(sp)
    800050ae:	ebda                	sd	s6,464(sp)
    800050b0:	e7de                	sd	s7,456(sp)
    800050b2:	e3e2                	sd	s8,448(sp)
    800050b4:	ff66                	sd	s9,440(sp)
    800050b6:	fb6a                	sd	s10,432(sp)
    800050b8:	f76e                	sd	s11,424(sp)
    800050ba:	0c00                	add	s0,sp,528
    800050bc:	892a                	mv	s2,a0
    800050be:	dea43c23          	sd	a0,-520(s0)
    800050c2:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800050c6:	ffffd097          	auipc	ra,0xffffd
    800050ca:	90a080e7          	jalr	-1782(ra) # 800019d0 <myproc>
    800050ce:	84aa                	mv	s1,a0

  begin_op();
    800050d0:	fffff097          	auipc	ra,0xfffff
    800050d4:	48e080e7          	jalr	1166(ra) # 8000455e <begin_op>

  if((ip = namei(path)) == 0){
    800050d8:	854a                	mv	a0,s2
    800050da:	fffff097          	auipc	ra,0xfffff
    800050de:	284080e7          	jalr	644(ra) # 8000435e <namei>
    800050e2:	c92d                	beqz	a0,80005154 <exec+0xbc>
    800050e4:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800050e6:	fffff097          	auipc	ra,0xfffff
    800050ea:	ad2080e7          	jalr	-1326(ra) # 80003bb8 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800050ee:	04000713          	li	a4,64
    800050f2:	4681                	li	a3,0
    800050f4:	e5040613          	add	a2,s0,-432
    800050f8:	4581                	li	a1,0
    800050fa:	8552                	mv	a0,s4
    800050fc:	fffff097          	auipc	ra,0xfffff
    80005100:	d70080e7          	jalr	-656(ra) # 80003e6c <readi>
    80005104:	04000793          	li	a5,64
    80005108:	00f51a63          	bne	a0,a5,8000511c <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    8000510c:	e5042703          	lw	a4,-432(s0)
    80005110:	464c47b7          	lui	a5,0x464c4
    80005114:	57f78793          	add	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005118:	04f70463          	beq	a4,a5,80005160 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000511c:	8552                	mv	a0,s4
    8000511e:	fffff097          	auipc	ra,0xfffff
    80005122:	cfc080e7          	jalr	-772(ra) # 80003e1a <iunlockput>
    end_op();
    80005126:	fffff097          	auipc	ra,0xfffff
    8000512a:	4b2080e7          	jalr	1202(ra) # 800045d8 <end_op>
  }
  return -1;
    8000512e:	557d                	li	a0,-1
}
    80005130:	20813083          	ld	ra,520(sp)
    80005134:	20013403          	ld	s0,512(sp)
    80005138:	74fe                	ld	s1,504(sp)
    8000513a:	795e                	ld	s2,496(sp)
    8000513c:	79be                	ld	s3,488(sp)
    8000513e:	7a1e                	ld	s4,480(sp)
    80005140:	6afe                	ld	s5,472(sp)
    80005142:	6b5e                	ld	s6,464(sp)
    80005144:	6bbe                	ld	s7,456(sp)
    80005146:	6c1e                	ld	s8,448(sp)
    80005148:	7cfa                	ld	s9,440(sp)
    8000514a:	7d5a                	ld	s10,432(sp)
    8000514c:	7dba                	ld	s11,424(sp)
    8000514e:	21010113          	add	sp,sp,528
    80005152:	8082                	ret
    end_op();
    80005154:	fffff097          	auipc	ra,0xfffff
    80005158:	484080e7          	jalr	1156(ra) # 800045d8 <end_op>
    return -1;
    8000515c:	557d                	li	a0,-1
    8000515e:	bfc9                	j	80005130 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005160:	8526                	mv	a0,s1
    80005162:	ffffd097          	auipc	ra,0xffffd
    80005166:	932080e7          	jalr	-1742(ra) # 80001a94 <proc_pagetable>
    8000516a:	8b2a                	mv	s6,a0
    8000516c:	d945                	beqz	a0,8000511c <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000516e:	e7042d03          	lw	s10,-400(s0)
    80005172:	e8845783          	lhu	a5,-376(s0)
    80005176:	10078463          	beqz	a5,8000527e <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000517a:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000517c:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    8000517e:	6c85                	lui	s9,0x1
    80005180:	fffc8793          	add	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005184:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80005188:	6a85                	lui	s5,0x1
    8000518a:	a0b5                	j	800051f6 <exec+0x15e>
      panic("loadseg: address should exist");
    8000518c:	00003517          	auipc	a0,0x3
    80005190:	56c50513          	add	a0,a0,1388 # 800086f8 <syscalls+0x298>
    80005194:	ffffb097          	auipc	ra,0xffffb
    80005198:	3a8080e7          	jalr	936(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    8000519c:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000519e:	8726                	mv	a4,s1
    800051a0:	012c06bb          	addw	a3,s8,s2
    800051a4:	4581                	li	a1,0
    800051a6:	8552                	mv	a0,s4
    800051a8:	fffff097          	auipc	ra,0xfffff
    800051ac:	cc4080e7          	jalr	-828(ra) # 80003e6c <readi>
    800051b0:	2501                	sext.w	a0,a0
    800051b2:	24a49863          	bne	s1,a0,80005402 <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    800051b6:	012a893b          	addw	s2,s5,s2
    800051ba:	03397563          	bgeu	s2,s3,800051e4 <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    800051be:	02091593          	sll	a1,s2,0x20
    800051c2:	9181                	srl	a1,a1,0x20
    800051c4:	95de                	add	a1,a1,s7
    800051c6:	855a                	mv	a0,s6
    800051c8:	ffffc097          	auipc	ra,0xffffc
    800051cc:	e8e080e7          	jalr	-370(ra) # 80001056 <walkaddr>
    800051d0:	862a                	mv	a2,a0
    if(pa == 0)
    800051d2:	dd4d                	beqz	a0,8000518c <exec+0xf4>
    if(sz - i < PGSIZE)
    800051d4:	412984bb          	subw	s1,s3,s2
    800051d8:	0004879b          	sext.w	a5,s1
    800051dc:	fcfcf0e3          	bgeu	s9,a5,8000519c <exec+0x104>
    800051e0:	84d6                	mv	s1,s5
    800051e2:	bf6d                	j	8000519c <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800051e4:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051e8:	2d85                	addw	s11,s11,1
    800051ea:	038d0d1b          	addw	s10,s10,56
    800051ee:	e8845783          	lhu	a5,-376(s0)
    800051f2:	08fdd763          	bge	s11,a5,80005280 <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800051f6:	2d01                	sext.w	s10,s10
    800051f8:	03800713          	li	a4,56
    800051fc:	86ea                	mv	a3,s10
    800051fe:	e1840613          	add	a2,s0,-488
    80005202:	4581                	li	a1,0
    80005204:	8552                	mv	a0,s4
    80005206:	fffff097          	auipc	ra,0xfffff
    8000520a:	c66080e7          	jalr	-922(ra) # 80003e6c <readi>
    8000520e:	03800793          	li	a5,56
    80005212:	1ef51663          	bne	a0,a5,800053fe <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    80005216:	e1842783          	lw	a5,-488(s0)
    8000521a:	4705                	li	a4,1
    8000521c:	fce796e3          	bne	a5,a4,800051e8 <exec+0x150>
    if(ph.memsz < ph.filesz)
    80005220:	e4043483          	ld	s1,-448(s0)
    80005224:	e3843783          	ld	a5,-456(s0)
    80005228:	1ef4e863          	bltu	s1,a5,80005418 <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000522c:	e2843783          	ld	a5,-472(s0)
    80005230:	94be                	add	s1,s1,a5
    80005232:	1ef4e663          	bltu	s1,a5,8000541e <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    80005236:	df043703          	ld	a4,-528(s0)
    8000523a:	8ff9                	and	a5,a5,a4
    8000523c:	1e079463          	bnez	a5,80005424 <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005240:	e1c42503          	lw	a0,-484(s0)
    80005244:	00000097          	auipc	ra,0x0
    80005248:	e3a080e7          	jalr	-454(ra) # 8000507e <flags2perm>
    8000524c:	86aa                	mv	a3,a0
    8000524e:	8626                	mv	a2,s1
    80005250:	85ca                	mv	a1,s2
    80005252:	855a                	mv	a0,s6
    80005254:	ffffc097          	auipc	ra,0xffffc
    80005258:	1a0080e7          	jalr	416(ra) # 800013f4 <uvmalloc>
    8000525c:	e0a43423          	sd	a0,-504(s0)
    80005260:	1c050563          	beqz	a0,8000542a <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005264:	e2843b83          	ld	s7,-472(s0)
    80005268:	e2042c03          	lw	s8,-480(s0)
    8000526c:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005270:	00098463          	beqz	s3,80005278 <exec+0x1e0>
    80005274:	4901                	li	s2,0
    80005276:	b7a1                	j	800051be <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005278:	e0843903          	ld	s2,-504(s0)
    8000527c:	b7b5                	j	800051e8 <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000527e:	4901                	li	s2,0
  iunlockput(ip);
    80005280:	8552                	mv	a0,s4
    80005282:	fffff097          	auipc	ra,0xfffff
    80005286:	b98080e7          	jalr	-1128(ra) # 80003e1a <iunlockput>
  end_op();
    8000528a:	fffff097          	auipc	ra,0xfffff
    8000528e:	34e080e7          	jalr	846(ra) # 800045d8 <end_op>
  p = myproc();
    80005292:	ffffc097          	auipc	ra,0xffffc
    80005296:	73e080e7          	jalr	1854(ra) # 800019d0 <myproc>
    8000529a:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000529c:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    800052a0:	6985                	lui	s3,0x1
    800052a2:	19fd                	add	s3,s3,-1 # fff <_entry-0x7ffff001>
    800052a4:	99ca                	add	s3,s3,s2
    800052a6:	77fd                	lui	a5,0xfffff
    800052a8:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800052ac:	4691                	li	a3,4
    800052ae:	6609                	lui	a2,0x2
    800052b0:	964e                	add	a2,a2,s3
    800052b2:	85ce                	mv	a1,s3
    800052b4:	855a                	mv	a0,s6
    800052b6:	ffffc097          	auipc	ra,0xffffc
    800052ba:	13e080e7          	jalr	318(ra) # 800013f4 <uvmalloc>
    800052be:	892a                	mv	s2,a0
    800052c0:	e0a43423          	sd	a0,-504(s0)
    800052c4:	e509                	bnez	a0,800052ce <exec+0x236>
  if(pagetable)
    800052c6:	e1343423          	sd	s3,-504(s0)
    800052ca:	4a01                	li	s4,0
    800052cc:	aa1d                	j	80005402 <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    800052ce:	75f9                	lui	a1,0xffffe
    800052d0:	95aa                	add	a1,a1,a0
    800052d2:	855a                	mv	a0,s6
    800052d4:	ffffc097          	auipc	ra,0xffffc
    800052d8:	31a080e7          	jalr	794(ra) # 800015ee <uvmclear>
  stackbase = sp - PGSIZE;
    800052dc:	7bfd                	lui	s7,0xfffff
    800052de:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    800052e0:	e0043783          	ld	a5,-512(s0)
    800052e4:	6388                	ld	a0,0(a5)
    800052e6:	c52d                	beqz	a0,80005350 <exec+0x2b8>
    800052e8:	e9040993          	add	s3,s0,-368
    800052ec:	f9040c13          	add	s8,s0,-112
    800052f0:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800052f2:	ffffc097          	auipc	ra,0xffffc
    800052f6:	b56080e7          	jalr	-1194(ra) # 80000e48 <strlen>
    800052fa:	0015079b          	addw	a5,a0,1
    800052fe:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005302:	ff07f913          	and	s2,a5,-16
    if(sp < stackbase)
    80005306:	13796563          	bltu	s2,s7,80005430 <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000530a:	e0043d03          	ld	s10,-512(s0)
    8000530e:	000d3a03          	ld	s4,0(s10)
    80005312:	8552                	mv	a0,s4
    80005314:	ffffc097          	auipc	ra,0xffffc
    80005318:	b34080e7          	jalr	-1228(ra) # 80000e48 <strlen>
    8000531c:	0015069b          	addw	a3,a0,1
    80005320:	8652                	mv	a2,s4
    80005322:	85ca                	mv	a1,s2
    80005324:	855a                	mv	a0,s6
    80005326:	ffffc097          	auipc	ra,0xffffc
    8000532a:	2fa080e7          	jalr	762(ra) # 80001620 <copyout>
    8000532e:	10054363          	bltz	a0,80005434 <exec+0x39c>
    ustack[argc] = sp;
    80005332:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005336:	0485                	add	s1,s1,1
    80005338:	008d0793          	add	a5,s10,8
    8000533c:	e0f43023          	sd	a5,-512(s0)
    80005340:	008d3503          	ld	a0,8(s10)
    80005344:	c909                	beqz	a0,80005356 <exec+0x2be>
    if(argc >= MAXARG)
    80005346:	09a1                	add	s3,s3,8
    80005348:	fb8995e3          	bne	s3,s8,800052f2 <exec+0x25a>
  ip = 0;
    8000534c:	4a01                	li	s4,0
    8000534e:	a855                	j	80005402 <exec+0x36a>
  sp = sz;
    80005350:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80005354:	4481                	li	s1,0
  ustack[argc] = 0;
    80005356:	00349793          	sll	a5,s1,0x3
    8000535a:	f9078793          	add	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdca20>
    8000535e:	97a2                	add	a5,a5,s0
    80005360:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005364:	00148693          	add	a3,s1,1
    80005368:	068e                	sll	a3,a3,0x3
    8000536a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000536e:	ff097913          	and	s2,s2,-16
  sz = sz1;
    80005372:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80005376:	f57968e3          	bltu	s2,s7,800052c6 <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000537a:	e9040613          	add	a2,s0,-368
    8000537e:	85ca                	mv	a1,s2
    80005380:	855a                	mv	a0,s6
    80005382:	ffffc097          	auipc	ra,0xffffc
    80005386:	29e080e7          	jalr	670(ra) # 80001620 <copyout>
    8000538a:	0a054763          	bltz	a0,80005438 <exec+0x3a0>
  p->trapframe->a1 = sp;
    8000538e:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80005392:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005396:	df843783          	ld	a5,-520(s0)
    8000539a:	0007c703          	lbu	a4,0(a5)
    8000539e:	cf11                	beqz	a4,800053ba <exec+0x322>
    800053a0:	0785                	add	a5,a5,1
    if(*s == '/')
    800053a2:	02f00693          	li	a3,47
    800053a6:	a039                	j	800053b4 <exec+0x31c>
      last = s+1;
    800053a8:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800053ac:	0785                	add	a5,a5,1
    800053ae:	fff7c703          	lbu	a4,-1(a5)
    800053b2:	c701                	beqz	a4,800053ba <exec+0x322>
    if(*s == '/')
    800053b4:	fed71ce3          	bne	a4,a3,800053ac <exec+0x314>
    800053b8:	bfc5                	j	800053a8 <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    800053ba:	4641                	li	a2,16
    800053bc:	df843583          	ld	a1,-520(s0)
    800053c0:	158a8513          	add	a0,s5,344
    800053c4:	ffffc097          	auipc	ra,0xffffc
    800053c8:	a52080e7          	jalr	-1454(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    800053cc:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800053d0:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    800053d4:	e0843783          	ld	a5,-504(s0)
    800053d8:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800053dc:	058ab783          	ld	a5,88(s5)
    800053e0:	e6843703          	ld	a4,-408(s0)
    800053e4:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800053e6:	058ab783          	ld	a5,88(s5)
    800053ea:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800053ee:	85e6                	mv	a1,s9
    800053f0:	ffffc097          	auipc	ra,0xffffc
    800053f4:	740080e7          	jalr	1856(ra) # 80001b30 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800053f8:	0004851b          	sext.w	a0,s1
    800053fc:	bb15                	j	80005130 <exec+0x98>
    800053fe:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005402:	e0843583          	ld	a1,-504(s0)
    80005406:	855a                	mv	a0,s6
    80005408:	ffffc097          	auipc	ra,0xffffc
    8000540c:	728080e7          	jalr	1832(ra) # 80001b30 <proc_freepagetable>
  return -1;
    80005410:	557d                	li	a0,-1
  if(ip){
    80005412:	d00a0fe3          	beqz	s4,80005130 <exec+0x98>
    80005416:	b319                	j	8000511c <exec+0x84>
    80005418:	e1243423          	sd	s2,-504(s0)
    8000541c:	b7dd                	j	80005402 <exec+0x36a>
    8000541e:	e1243423          	sd	s2,-504(s0)
    80005422:	b7c5                	j	80005402 <exec+0x36a>
    80005424:	e1243423          	sd	s2,-504(s0)
    80005428:	bfe9                	j	80005402 <exec+0x36a>
    8000542a:	e1243423          	sd	s2,-504(s0)
    8000542e:	bfd1                	j	80005402 <exec+0x36a>
  ip = 0;
    80005430:	4a01                	li	s4,0
    80005432:	bfc1                	j	80005402 <exec+0x36a>
    80005434:	4a01                	li	s4,0
  if(pagetable)
    80005436:	b7f1                	j	80005402 <exec+0x36a>
  sz = sz1;
    80005438:	e0843983          	ld	s3,-504(s0)
    8000543c:	b569                	j	800052c6 <exec+0x22e>

000000008000543e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000543e:	7179                	add	sp,sp,-48
    80005440:	f406                	sd	ra,40(sp)
    80005442:	f022                	sd	s0,32(sp)
    80005444:	ec26                	sd	s1,24(sp)
    80005446:	e84a                	sd	s2,16(sp)
    80005448:	1800                	add	s0,sp,48
    8000544a:	892e                	mv	s2,a1
    8000544c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000544e:	fdc40593          	add	a1,s0,-36
    80005452:	ffffe097          	auipc	ra,0xffffe
    80005456:	aba080e7          	jalr	-1350(ra) # 80002f0c <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000545a:	fdc42703          	lw	a4,-36(s0)
    8000545e:	47bd                	li	a5,15
    80005460:	02e7eb63          	bltu	a5,a4,80005496 <argfd+0x58>
    80005464:	ffffc097          	auipc	ra,0xffffc
    80005468:	56c080e7          	jalr	1388(ra) # 800019d0 <myproc>
    8000546c:	fdc42703          	lw	a4,-36(s0)
    80005470:	01a70793          	add	a5,a4,26
    80005474:	078e                	sll	a5,a5,0x3
    80005476:	953e                	add	a0,a0,a5
    80005478:	611c                	ld	a5,0(a0)
    8000547a:	c385                	beqz	a5,8000549a <argfd+0x5c>
    return -1;
  if(pfd)
    8000547c:	00090463          	beqz	s2,80005484 <argfd+0x46>
    *pfd = fd;
    80005480:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005484:	4501                	li	a0,0
  if(pf)
    80005486:	c091                	beqz	s1,8000548a <argfd+0x4c>
    *pf = f;
    80005488:	e09c                	sd	a5,0(s1)
}
    8000548a:	70a2                	ld	ra,40(sp)
    8000548c:	7402                	ld	s0,32(sp)
    8000548e:	64e2                	ld	s1,24(sp)
    80005490:	6942                	ld	s2,16(sp)
    80005492:	6145                	add	sp,sp,48
    80005494:	8082                	ret
    return -1;
    80005496:	557d                	li	a0,-1
    80005498:	bfcd                	j	8000548a <argfd+0x4c>
    8000549a:	557d                	li	a0,-1
    8000549c:	b7fd                	j	8000548a <argfd+0x4c>

000000008000549e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000549e:	1101                	add	sp,sp,-32
    800054a0:	ec06                	sd	ra,24(sp)
    800054a2:	e822                	sd	s0,16(sp)
    800054a4:	e426                	sd	s1,8(sp)
    800054a6:	1000                	add	s0,sp,32
    800054a8:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800054aa:	ffffc097          	auipc	ra,0xffffc
    800054ae:	526080e7          	jalr	1318(ra) # 800019d0 <myproc>
    800054b2:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800054b4:	0d050793          	add	a5,a0,208
    800054b8:	4501                	li	a0,0
    800054ba:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800054bc:	6398                	ld	a4,0(a5)
    800054be:	cb19                	beqz	a4,800054d4 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800054c0:	2505                	addw	a0,a0,1
    800054c2:	07a1                	add	a5,a5,8
    800054c4:	fed51ce3          	bne	a0,a3,800054bc <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800054c8:	557d                	li	a0,-1
}
    800054ca:	60e2                	ld	ra,24(sp)
    800054cc:	6442                	ld	s0,16(sp)
    800054ce:	64a2                	ld	s1,8(sp)
    800054d0:	6105                	add	sp,sp,32
    800054d2:	8082                	ret
      p->ofile[fd] = f;
    800054d4:	01a50793          	add	a5,a0,26
    800054d8:	078e                	sll	a5,a5,0x3
    800054da:	963e                	add	a2,a2,a5
    800054dc:	e204                	sd	s1,0(a2)
      return fd;
    800054de:	b7f5                	j	800054ca <fdalloc+0x2c>

00000000800054e0 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800054e0:	715d                	add	sp,sp,-80
    800054e2:	e486                	sd	ra,72(sp)
    800054e4:	e0a2                	sd	s0,64(sp)
    800054e6:	fc26                	sd	s1,56(sp)
    800054e8:	f84a                	sd	s2,48(sp)
    800054ea:	f44e                	sd	s3,40(sp)
    800054ec:	f052                	sd	s4,32(sp)
    800054ee:	ec56                	sd	s5,24(sp)
    800054f0:	e85a                	sd	s6,16(sp)
    800054f2:	0880                	add	s0,sp,80
    800054f4:	8b2e                	mv	s6,a1
    800054f6:	89b2                	mv	s3,a2
    800054f8:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800054fa:	fb040593          	add	a1,s0,-80
    800054fe:	fffff097          	auipc	ra,0xfffff
    80005502:	e7e080e7          	jalr	-386(ra) # 8000437c <nameiparent>
    80005506:	84aa                	mv	s1,a0
    80005508:	14050b63          	beqz	a0,8000565e <create+0x17e>
    return 0;

  ilock(dp);
    8000550c:	ffffe097          	auipc	ra,0xffffe
    80005510:	6ac080e7          	jalr	1708(ra) # 80003bb8 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005514:	4601                	li	a2,0
    80005516:	fb040593          	add	a1,s0,-80
    8000551a:	8526                	mv	a0,s1
    8000551c:	fffff097          	auipc	ra,0xfffff
    80005520:	b80080e7          	jalr	-1152(ra) # 8000409c <dirlookup>
    80005524:	8aaa                	mv	s5,a0
    80005526:	c921                	beqz	a0,80005576 <create+0x96>
    iunlockput(dp);
    80005528:	8526                	mv	a0,s1
    8000552a:	fffff097          	auipc	ra,0xfffff
    8000552e:	8f0080e7          	jalr	-1808(ra) # 80003e1a <iunlockput>
    ilock(ip);
    80005532:	8556                	mv	a0,s5
    80005534:	ffffe097          	auipc	ra,0xffffe
    80005538:	684080e7          	jalr	1668(ra) # 80003bb8 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000553c:	4789                	li	a5,2
    8000553e:	02fb1563          	bne	s6,a5,80005568 <create+0x88>
    80005542:	044ad783          	lhu	a5,68(s5)
    80005546:	37f9                	addw	a5,a5,-2
    80005548:	17c2                	sll	a5,a5,0x30
    8000554a:	93c1                	srl	a5,a5,0x30
    8000554c:	4705                	li	a4,1
    8000554e:	00f76d63          	bltu	a4,a5,80005568 <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005552:	8556                	mv	a0,s5
    80005554:	60a6                	ld	ra,72(sp)
    80005556:	6406                	ld	s0,64(sp)
    80005558:	74e2                	ld	s1,56(sp)
    8000555a:	7942                	ld	s2,48(sp)
    8000555c:	79a2                	ld	s3,40(sp)
    8000555e:	7a02                	ld	s4,32(sp)
    80005560:	6ae2                	ld	s5,24(sp)
    80005562:	6b42                	ld	s6,16(sp)
    80005564:	6161                	add	sp,sp,80
    80005566:	8082                	ret
    iunlockput(ip);
    80005568:	8556                	mv	a0,s5
    8000556a:	fffff097          	auipc	ra,0xfffff
    8000556e:	8b0080e7          	jalr	-1872(ra) # 80003e1a <iunlockput>
    return 0;
    80005572:	4a81                	li	s5,0
    80005574:	bff9                	j	80005552 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005576:	85da                	mv	a1,s6
    80005578:	4088                	lw	a0,0(s1)
    8000557a:	ffffe097          	auipc	ra,0xffffe
    8000557e:	4a6080e7          	jalr	1190(ra) # 80003a20 <ialloc>
    80005582:	8a2a                	mv	s4,a0
    80005584:	c529                	beqz	a0,800055ce <create+0xee>
  ilock(ip);
    80005586:	ffffe097          	auipc	ra,0xffffe
    8000558a:	632080e7          	jalr	1586(ra) # 80003bb8 <ilock>
  ip->major = major;
    8000558e:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005592:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005596:	4905                	li	s2,1
    80005598:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000559c:	8552                	mv	a0,s4
    8000559e:	ffffe097          	auipc	ra,0xffffe
    800055a2:	54e080e7          	jalr	1358(ra) # 80003aec <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800055a6:	032b0b63          	beq	s6,s2,800055dc <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800055aa:	004a2603          	lw	a2,4(s4)
    800055ae:	fb040593          	add	a1,s0,-80
    800055b2:	8526                	mv	a0,s1
    800055b4:	fffff097          	auipc	ra,0xfffff
    800055b8:	cf8080e7          	jalr	-776(ra) # 800042ac <dirlink>
    800055bc:	06054f63          	bltz	a0,8000563a <create+0x15a>
  iunlockput(dp);
    800055c0:	8526                	mv	a0,s1
    800055c2:	fffff097          	auipc	ra,0xfffff
    800055c6:	858080e7          	jalr	-1960(ra) # 80003e1a <iunlockput>
  return ip;
    800055ca:	8ad2                	mv	s5,s4
    800055cc:	b759                	j	80005552 <create+0x72>
    iunlockput(dp);
    800055ce:	8526                	mv	a0,s1
    800055d0:	fffff097          	auipc	ra,0xfffff
    800055d4:	84a080e7          	jalr	-1974(ra) # 80003e1a <iunlockput>
    return 0;
    800055d8:	8ad2                	mv	s5,s4
    800055da:	bfa5                	j	80005552 <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800055dc:	004a2603          	lw	a2,4(s4)
    800055e0:	00003597          	auipc	a1,0x3
    800055e4:	13858593          	add	a1,a1,312 # 80008718 <syscalls+0x2b8>
    800055e8:	8552                	mv	a0,s4
    800055ea:	fffff097          	auipc	ra,0xfffff
    800055ee:	cc2080e7          	jalr	-830(ra) # 800042ac <dirlink>
    800055f2:	04054463          	bltz	a0,8000563a <create+0x15a>
    800055f6:	40d0                	lw	a2,4(s1)
    800055f8:	00003597          	auipc	a1,0x3
    800055fc:	12858593          	add	a1,a1,296 # 80008720 <syscalls+0x2c0>
    80005600:	8552                	mv	a0,s4
    80005602:	fffff097          	auipc	ra,0xfffff
    80005606:	caa080e7          	jalr	-854(ra) # 800042ac <dirlink>
    8000560a:	02054863          	bltz	a0,8000563a <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    8000560e:	004a2603          	lw	a2,4(s4)
    80005612:	fb040593          	add	a1,s0,-80
    80005616:	8526                	mv	a0,s1
    80005618:	fffff097          	auipc	ra,0xfffff
    8000561c:	c94080e7          	jalr	-876(ra) # 800042ac <dirlink>
    80005620:	00054d63          	bltz	a0,8000563a <create+0x15a>
    dp->nlink++;  // for ".."
    80005624:	04a4d783          	lhu	a5,74(s1)
    80005628:	2785                	addw	a5,a5,1
    8000562a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000562e:	8526                	mv	a0,s1
    80005630:	ffffe097          	auipc	ra,0xffffe
    80005634:	4bc080e7          	jalr	1212(ra) # 80003aec <iupdate>
    80005638:	b761                	j	800055c0 <create+0xe0>
  ip->nlink = 0;
    8000563a:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000563e:	8552                	mv	a0,s4
    80005640:	ffffe097          	auipc	ra,0xffffe
    80005644:	4ac080e7          	jalr	1196(ra) # 80003aec <iupdate>
  iunlockput(ip);
    80005648:	8552                	mv	a0,s4
    8000564a:	ffffe097          	auipc	ra,0xffffe
    8000564e:	7d0080e7          	jalr	2000(ra) # 80003e1a <iunlockput>
  iunlockput(dp);
    80005652:	8526                	mv	a0,s1
    80005654:	ffffe097          	auipc	ra,0xffffe
    80005658:	7c6080e7          	jalr	1990(ra) # 80003e1a <iunlockput>
  return 0;
    8000565c:	bddd                	j	80005552 <create+0x72>
    return 0;
    8000565e:	8aaa                	mv	s5,a0
    80005660:	bdcd                	j	80005552 <create+0x72>

0000000080005662 <sys_dup>:
{
    80005662:	7179                	add	sp,sp,-48
    80005664:	f406                	sd	ra,40(sp)
    80005666:	f022                	sd	s0,32(sp)
    80005668:	ec26                	sd	s1,24(sp)
    8000566a:	e84a                	sd	s2,16(sp)
    8000566c:	1800                	add	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000566e:	fd840613          	add	a2,s0,-40
    80005672:	4581                	li	a1,0
    80005674:	4501                	li	a0,0
    80005676:	00000097          	auipc	ra,0x0
    8000567a:	dc8080e7          	jalr	-568(ra) # 8000543e <argfd>
    return -1;
    8000567e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005680:	02054363          	bltz	a0,800056a6 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005684:	fd843903          	ld	s2,-40(s0)
    80005688:	854a                	mv	a0,s2
    8000568a:	00000097          	auipc	ra,0x0
    8000568e:	e14080e7          	jalr	-492(ra) # 8000549e <fdalloc>
    80005692:	84aa                	mv	s1,a0
    return -1;
    80005694:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005696:	00054863          	bltz	a0,800056a6 <sys_dup+0x44>
  filedup(f);
    8000569a:	854a                	mv	a0,s2
    8000569c:	fffff097          	auipc	ra,0xfffff
    800056a0:	334080e7          	jalr	820(ra) # 800049d0 <filedup>
  return fd;
    800056a4:	87a6                	mv	a5,s1
}
    800056a6:	853e                	mv	a0,a5
    800056a8:	70a2                	ld	ra,40(sp)
    800056aa:	7402                	ld	s0,32(sp)
    800056ac:	64e2                	ld	s1,24(sp)
    800056ae:	6942                	ld	s2,16(sp)
    800056b0:	6145                	add	sp,sp,48
    800056b2:	8082                	ret

00000000800056b4 <sys_getreadcount>:
{
    800056b4:	1141                	add	sp,sp,-16
    800056b6:	e422                	sd	s0,8(sp)
    800056b8:	0800                	add	s0,sp,16
}
    800056ba:	00003517          	auipc	a0,0x3
    800056be:	23a52503          	lw	a0,570(a0) # 800088f4 <readCount>
    800056c2:	6422                	ld	s0,8(sp)
    800056c4:	0141                	add	sp,sp,16
    800056c6:	8082                	ret

00000000800056c8 <sys_read>:
{
    800056c8:	7179                	add	sp,sp,-48
    800056ca:	f406                	sd	ra,40(sp)
    800056cc:	f022                	sd	s0,32(sp)
    800056ce:	1800                	add	s0,sp,48
  readCount++;
    800056d0:	00003717          	auipc	a4,0x3
    800056d4:	22470713          	add	a4,a4,548 # 800088f4 <readCount>
    800056d8:	431c                	lw	a5,0(a4)
    800056da:	2785                	addw	a5,a5,1
    800056dc:	c31c                	sw	a5,0(a4)
  argaddr(1, &p);
    800056de:	fd840593          	add	a1,s0,-40
    800056e2:	4505                	li	a0,1
    800056e4:	ffffe097          	auipc	ra,0xffffe
    800056e8:	848080e7          	jalr	-1976(ra) # 80002f2c <argaddr>
  argint(2, &n);
    800056ec:	fe440593          	add	a1,s0,-28
    800056f0:	4509                	li	a0,2
    800056f2:	ffffe097          	auipc	ra,0xffffe
    800056f6:	81a080e7          	jalr	-2022(ra) # 80002f0c <argint>
  if(argfd(0, 0, &f) < 0)
    800056fa:	fe840613          	add	a2,s0,-24
    800056fe:	4581                	li	a1,0
    80005700:	4501                	li	a0,0
    80005702:	00000097          	auipc	ra,0x0
    80005706:	d3c080e7          	jalr	-708(ra) # 8000543e <argfd>
    8000570a:	87aa                	mv	a5,a0
    return -1;
    8000570c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000570e:	0007cc63          	bltz	a5,80005726 <sys_read+0x5e>
  return fileread(f, p, n);
    80005712:	fe442603          	lw	a2,-28(s0)
    80005716:	fd843583          	ld	a1,-40(s0)
    8000571a:	fe843503          	ld	a0,-24(s0)
    8000571e:	fffff097          	auipc	ra,0xfffff
    80005722:	43e080e7          	jalr	1086(ra) # 80004b5c <fileread>
}
    80005726:	70a2                	ld	ra,40(sp)
    80005728:	7402                	ld	s0,32(sp)
    8000572a:	6145                	add	sp,sp,48
    8000572c:	8082                	ret

000000008000572e <sys_write>:
{
    8000572e:	7179                	add	sp,sp,-48
    80005730:	f406                	sd	ra,40(sp)
    80005732:	f022                	sd	s0,32(sp)
    80005734:	1800                	add	s0,sp,48
  argaddr(1, &p);
    80005736:	fd840593          	add	a1,s0,-40
    8000573a:	4505                	li	a0,1
    8000573c:	ffffd097          	auipc	ra,0xffffd
    80005740:	7f0080e7          	jalr	2032(ra) # 80002f2c <argaddr>
  argint(2, &n);
    80005744:	fe440593          	add	a1,s0,-28
    80005748:	4509                	li	a0,2
    8000574a:	ffffd097          	auipc	ra,0xffffd
    8000574e:	7c2080e7          	jalr	1986(ra) # 80002f0c <argint>
  if(argfd(0, 0, &f) < 0)
    80005752:	fe840613          	add	a2,s0,-24
    80005756:	4581                	li	a1,0
    80005758:	4501                	li	a0,0
    8000575a:	00000097          	auipc	ra,0x0
    8000575e:	ce4080e7          	jalr	-796(ra) # 8000543e <argfd>
    80005762:	87aa                	mv	a5,a0
    return -1;
    80005764:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005766:	0007cc63          	bltz	a5,8000577e <sys_write+0x50>
  return filewrite(f, p, n);
    8000576a:	fe442603          	lw	a2,-28(s0)
    8000576e:	fd843583          	ld	a1,-40(s0)
    80005772:	fe843503          	ld	a0,-24(s0)
    80005776:	fffff097          	auipc	ra,0xfffff
    8000577a:	4a8080e7          	jalr	1192(ra) # 80004c1e <filewrite>
}
    8000577e:	70a2                	ld	ra,40(sp)
    80005780:	7402                	ld	s0,32(sp)
    80005782:	6145                	add	sp,sp,48
    80005784:	8082                	ret

0000000080005786 <sys_close>:
{
    80005786:	1101                	add	sp,sp,-32
    80005788:	ec06                	sd	ra,24(sp)
    8000578a:	e822                	sd	s0,16(sp)
    8000578c:	1000                	add	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000578e:	fe040613          	add	a2,s0,-32
    80005792:	fec40593          	add	a1,s0,-20
    80005796:	4501                	li	a0,0
    80005798:	00000097          	auipc	ra,0x0
    8000579c:	ca6080e7          	jalr	-858(ra) # 8000543e <argfd>
    return -1;
    800057a0:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800057a2:	02054463          	bltz	a0,800057ca <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800057a6:	ffffc097          	auipc	ra,0xffffc
    800057aa:	22a080e7          	jalr	554(ra) # 800019d0 <myproc>
    800057ae:	fec42783          	lw	a5,-20(s0)
    800057b2:	07e9                	add	a5,a5,26
    800057b4:	078e                	sll	a5,a5,0x3
    800057b6:	953e                	add	a0,a0,a5
    800057b8:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800057bc:	fe043503          	ld	a0,-32(s0)
    800057c0:	fffff097          	auipc	ra,0xfffff
    800057c4:	262080e7          	jalr	610(ra) # 80004a22 <fileclose>
  return 0;
    800057c8:	4781                	li	a5,0
}
    800057ca:	853e                	mv	a0,a5
    800057cc:	60e2                	ld	ra,24(sp)
    800057ce:	6442                	ld	s0,16(sp)
    800057d0:	6105                	add	sp,sp,32
    800057d2:	8082                	ret

00000000800057d4 <sys_fstat>:
{
    800057d4:	1101                	add	sp,sp,-32
    800057d6:	ec06                	sd	ra,24(sp)
    800057d8:	e822                	sd	s0,16(sp)
    800057da:	1000                	add	s0,sp,32
  argaddr(1, &st);
    800057dc:	fe040593          	add	a1,s0,-32
    800057e0:	4505                	li	a0,1
    800057e2:	ffffd097          	auipc	ra,0xffffd
    800057e6:	74a080e7          	jalr	1866(ra) # 80002f2c <argaddr>
  if(argfd(0, 0, &f) < 0)
    800057ea:	fe840613          	add	a2,s0,-24
    800057ee:	4581                	li	a1,0
    800057f0:	4501                	li	a0,0
    800057f2:	00000097          	auipc	ra,0x0
    800057f6:	c4c080e7          	jalr	-948(ra) # 8000543e <argfd>
    800057fa:	87aa                	mv	a5,a0
    return -1;
    800057fc:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800057fe:	0007ca63          	bltz	a5,80005812 <sys_fstat+0x3e>
  return filestat(f, st);
    80005802:	fe043583          	ld	a1,-32(s0)
    80005806:	fe843503          	ld	a0,-24(s0)
    8000580a:	fffff097          	auipc	ra,0xfffff
    8000580e:	2e0080e7          	jalr	736(ra) # 80004aea <filestat>
}
    80005812:	60e2                	ld	ra,24(sp)
    80005814:	6442                	ld	s0,16(sp)
    80005816:	6105                	add	sp,sp,32
    80005818:	8082                	ret

000000008000581a <sys_link>:
{
    8000581a:	7169                	add	sp,sp,-304
    8000581c:	f606                	sd	ra,296(sp)
    8000581e:	f222                	sd	s0,288(sp)
    80005820:	ee26                	sd	s1,280(sp)
    80005822:	ea4a                	sd	s2,272(sp)
    80005824:	1a00                	add	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005826:	08000613          	li	a2,128
    8000582a:	ed040593          	add	a1,s0,-304
    8000582e:	4501                	li	a0,0
    80005830:	ffffd097          	auipc	ra,0xffffd
    80005834:	71c080e7          	jalr	1820(ra) # 80002f4c <argstr>
    return -1;
    80005838:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000583a:	10054e63          	bltz	a0,80005956 <sys_link+0x13c>
    8000583e:	08000613          	li	a2,128
    80005842:	f5040593          	add	a1,s0,-176
    80005846:	4505                	li	a0,1
    80005848:	ffffd097          	auipc	ra,0xffffd
    8000584c:	704080e7          	jalr	1796(ra) # 80002f4c <argstr>
    return -1;
    80005850:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005852:	10054263          	bltz	a0,80005956 <sys_link+0x13c>
  begin_op();
    80005856:	fffff097          	auipc	ra,0xfffff
    8000585a:	d08080e7          	jalr	-760(ra) # 8000455e <begin_op>
  if((ip = namei(old)) == 0){
    8000585e:	ed040513          	add	a0,s0,-304
    80005862:	fffff097          	auipc	ra,0xfffff
    80005866:	afc080e7          	jalr	-1284(ra) # 8000435e <namei>
    8000586a:	84aa                	mv	s1,a0
    8000586c:	c551                	beqz	a0,800058f8 <sys_link+0xde>
  ilock(ip);
    8000586e:	ffffe097          	auipc	ra,0xffffe
    80005872:	34a080e7          	jalr	842(ra) # 80003bb8 <ilock>
  if(ip->type == T_DIR){
    80005876:	04449703          	lh	a4,68(s1)
    8000587a:	4785                	li	a5,1
    8000587c:	08f70463          	beq	a4,a5,80005904 <sys_link+0xea>
  ip->nlink++;
    80005880:	04a4d783          	lhu	a5,74(s1)
    80005884:	2785                	addw	a5,a5,1
    80005886:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000588a:	8526                	mv	a0,s1
    8000588c:	ffffe097          	auipc	ra,0xffffe
    80005890:	260080e7          	jalr	608(ra) # 80003aec <iupdate>
  iunlock(ip);
    80005894:	8526                	mv	a0,s1
    80005896:	ffffe097          	auipc	ra,0xffffe
    8000589a:	3e4080e7          	jalr	996(ra) # 80003c7a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000589e:	fd040593          	add	a1,s0,-48
    800058a2:	f5040513          	add	a0,s0,-176
    800058a6:	fffff097          	auipc	ra,0xfffff
    800058aa:	ad6080e7          	jalr	-1322(ra) # 8000437c <nameiparent>
    800058ae:	892a                	mv	s2,a0
    800058b0:	c935                	beqz	a0,80005924 <sys_link+0x10a>
  ilock(dp);
    800058b2:	ffffe097          	auipc	ra,0xffffe
    800058b6:	306080e7          	jalr	774(ra) # 80003bb8 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800058ba:	00092703          	lw	a4,0(s2)
    800058be:	409c                	lw	a5,0(s1)
    800058c0:	04f71d63          	bne	a4,a5,8000591a <sys_link+0x100>
    800058c4:	40d0                	lw	a2,4(s1)
    800058c6:	fd040593          	add	a1,s0,-48
    800058ca:	854a                	mv	a0,s2
    800058cc:	fffff097          	auipc	ra,0xfffff
    800058d0:	9e0080e7          	jalr	-1568(ra) # 800042ac <dirlink>
    800058d4:	04054363          	bltz	a0,8000591a <sys_link+0x100>
  iunlockput(dp);
    800058d8:	854a                	mv	a0,s2
    800058da:	ffffe097          	auipc	ra,0xffffe
    800058de:	540080e7          	jalr	1344(ra) # 80003e1a <iunlockput>
  iput(ip);
    800058e2:	8526                	mv	a0,s1
    800058e4:	ffffe097          	auipc	ra,0xffffe
    800058e8:	48e080e7          	jalr	1166(ra) # 80003d72 <iput>
  end_op();
    800058ec:	fffff097          	auipc	ra,0xfffff
    800058f0:	cec080e7          	jalr	-788(ra) # 800045d8 <end_op>
  return 0;
    800058f4:	4781                	li	a5,0
    800058f6:	a085                	j	80005956 <sys_link+0x13c>
    end_op();
    800058f8:	fffff097          	auipc	ra,0xfffff
    800058fc:	ce0080e7          	jalr	-800(ra) # 800045d8 <end_op>
    return -1;
    80005900:	57fd                	li	a5,-1
    80005902:	a891                	j	80005956 <sys_link+0x13c>
    iunlockput(ip);
    80005904:	8526                	mv	a0,s1
    80005906:	ffffe097          	auipc	ra,0xffffe
    8000590a:	514080e7          	jalr	1300(ra) # 80003e1a <iunlockput>
    end_op();
    8000590e:	fffff097          	auipc	ra,0xfffff
    80005912:	cca080e7          	jalr	-822(ra) # 800045d8 <end_op>
    return -1;
    80005916:	57fd                	li	a5,-1
    80005918:	a83d                	j	80005956 <sys_link+0x13c>
    iunlockput(dp);
    8000591a:	854a                	mv	a0,s2
    8000591c:	ffffe097          	auipc	ra,0xffffe
    80005920:	4fe080e7          	jalr	1278(ra) # 80003e1a <iunlockput>
  ilock(ip);
    80005924:	8526                	mv	a0,s1
    80005926:	ffffe097          	auipc	ra,0xffffe
    8000592a:	292080e7          	jalr	658(ra) # 80003bb8 <ilock>
  ip->nlink--;
    8000592e:	04a4d783          	lhu	a5,74(s1)
    80005932:	37fd                	addw	a5,a5,-1
    80005934:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005938:	8526                	mv	a0,s1
    8000593a:	ffffe097          	auipc	ra,0xffffe
    8000593e:	1b2080e7          	jalr	434(ra) # 80003aec <iupdate>
  iunlockput(ip);
    80005942:	8526                	mv	a0,s1
    80005944:	ffffe097          	auipc	ra,0xffffe
    80005948:	4d6080e7          	jalr	1238(ra) # 80003e1a <iunlockput>
  end_op();
    8000594c:	fffff097          	auipc	ra,0xfffff
    80005950:	c8c080e7          	jalr	-884(ra) # 800045d8 <end_op>
  return -1;
    80005954:	57fd                	li	a5,-1
}
    80005956:	853e                	mv	a0,a5
    80005958:	70b2                	ld	ra,296(sp)
    8000595a:	7412                	ld	s0,288(sp)
    8000595c:	64f2                	ld	s1,280(sp)
    8000595e:	6952                	ld	s2,272(sp)
    80005960:	6155                	add	sp,sp,304
    80005962:	8082                	ret

0000000080005964 <sys_unlink>:
{
    80005964:	7151                	add	sp,sp,-240
    80005966:	f586                	sd	ra,232(sp)
    80005968:	f1a2                	sd	s0,224(sp)
    8000596a:	eda6                	sd	s1,216(sp)
    8000596c:	e9ca                	sd	s2,208(sp)
    8000596e:	e5ce                	sd	s3,200(sp)
    80005970:	1980                	add	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005972:	08000613          	li	a2,128
    80005976:	f3040593          	add	a1,s0,-208
    8000597a:	4501                	li	a0,0
    8000597c:	ffffd097          	auipc	ra,0xffffd
    80005980:	5d0080e7          	jalr	1488(ra) # 80002f4c <argstr>
    80005984:	18054163          	bltz	a0,80005b06 <sys_unlink+0x1a2>
  begin_op();
    80005988:	fffff097          	auipc	ra,0xfffff
    8000598c:	bd6080e7          	jalr	-1066(ra) # 8000455e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005990:	fb040593          	add	a1,s0,-80
    80005994:	f3040513          	add	a0,s0,-208
    80005998:	fffff097          	auipc	ra,0xfffff
    8000599c:	9e4080e7          	jalr	-1564(ra) # 8000437c <nameiparent>
    800059a0:	84aa                	mv	s1,a0
    800059a2:	c979                	beqz	a0,80005a78 <sys_unlink+0x114>
  ilock(dp);
    800059a4:	ffffe097          	auipc	ra,0xffffe
    800059a8:	214080e7          	jalr	532(ra) # 80003bb8 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800059ac:	00003597          	auipc	a1,0x3
    800059b0:	d6c58593          	add	a1,a1,-660 # 80008718 <syscalls+0x2b8>
    800059b4:	fb040513          	add	a0,s0,-80
    800059b8:	ffffe097          	auipc	ra,0xffffe
    800059bc:	6ca080e7          	jalr	1738(ra) # 80004082 <namecmp>
    800059c0:	14050a63          	beqz	a0,80005b14 <sys_unlink+0x1b0>
    800059c4:	00003597          	auipc	a1,0x3
    800059c8:	d5c58593          	add	a1,a1,-676 # 80008720 <syscalls+0x2c0>
    800059cc:	fb040513          	add	a0,s0,-80
    800059d0:	ffffe097          	auipc	ra,0xffffe
    800059d4:	6b2080e7          	jalr	1714(ra) # 80004082 <namecmp>
    800059d8:	12050e63          	beqz	a0,80005b14 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800059dc:	f2c40613          	add	a2,s0,-212
    800059e0:	fb040593          	add	a1,s0,-80
    800059e4:	8526                	mv	a0,s1
    800059e6:	ffffe097          	auipc	ra,0xffffe
    800059ea:	6b6080e7          	jalr	1718(ra) # 8000409c <dirlookup>
    800059ee:	892a                	mv	s2,a0
    800059f0:	12050263          	beqz	a0,80005b14 <sys_unlink+0x1b0>
  ilock(ip);
    800059f4:	ffffe097          	auipc	ra,0xffffe
    800059f8:	1c4080e7          	jalr	452(ra) # 80003bb8 <ilock>
  if(ip->nlink < 1)
    800059fc:	04a91783          	lh	a5,74(s2)
    80005a00:	08f05263          	blez	a5,80005a84 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005a04:	04491703          	lh	a4,68(s2)
    80005a08:	4785                	li	a5,1
    80005a0a:	08f70563          	beq	a4,a5,80005a94 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005a0e:	4641                	li	a2,16
    80005a10:	4581                	li	a1,0
    80005a12:	fc040513          	add	a0,s0,-64
    80005a16:	ffffb097          	auipc	ra,0xffffb
    80005a1a:	2b8080e7          	jalr	696(ra) # 80000cce <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a1e:	4741                	li	a4,16
    80005a20:	f2c42683          	lw	a3,-212(s0)
    80005a24:	fc040613          	add	a2,s0,-64
    80005a28:	4581                	li	a1,0
    80005a2a:	8526                	mv	a0,s1
    80005a2c:	ffffe097          	auipc	ra,0xffffe
    80005a30:	538080e7          	jalr	1336(ra) # 80003f64 <writei>
    80005a34:	47c1                	li	a5,16
    80005a36:	0af51563          	bne	a0,a5,80005ae0 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005a3a:	04491703          	lh	a4,68(s2)
    80005a3e:	4785                	li	a5,1
    80005a40:	0af70863          	beq	a4,a5,80005af0 <sys_unlink+0x18c>
  iunlockput(dp);
    80005a44:	8526                	mv	a0,s1
    80005a46:	ffffe097          	auipc	ra,0xffffe
    80005a4a:	3d4080e7          	jalr	980(ra) # 80003e1a <iunlockput>
  ip->nlink--;
    80005a4e:	04a95783          	lhu	a5,74(s2)
    80005a52:	37fd                	addw	a5,a5,-1
    80005a54:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005a58:	854a                	mv	a0,s2
    80005a5a:	ffffe097          	auipc	ra,0xffffe
    80005a5e:	092080e7          	jalr	146(ra) # 80003aec <iupdate>
  iunlockput(ip);
    80005a62:	854a                	mv	a0,s2
    80005a64:	ffffe097          	auipc	ra,0xffffe
    80005a68:	3b6080e7          	jalr	950(ra) # 80003e1a <iunlockput>
  end_op();
    80005a6c:	fffff097          	auipc	ra,0xfffff
    80005a70:	b6c080e7          	jalr	-1172(ra) # 800045d8 <end_op>
  return 0;
    80005a74:	4501                	li	a0,0
    80005a76:	a84d                	j	80005b28 <sys_unlink+0x1c4>
    end_op();
    80005a78:	fffff097          	auipc	ra,0xfffff
    80005a7c:	b60080e7          	jalr	-1184(ra) # 800045d8 <end_op>
    return -1;
    80005a80:	557d                	li	a0,-1
    80005a82:	a05d                	j	80005b28 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005a84:	00003517          	auipc	a0,0x3
    80005a88:	ca450513          	add	a0,a0,-860 # 80008728 <syscalls+0x2c8>
    80005a8c:	ffffb097          	auipc	ra,0xffffb
    80005a90:	ab0080e7          	jalr	-1360(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a94:	04c92703          	lw	a4,76(s2)
    80005a98:	02000793          	li	a5,32
    80005a9c:	f6e7f9e3          	bgeu	a5,a4,80005a0e <sys_unlink+0xaa>
    80005aa0:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005aa4:	4741                	li	a4,16
    80005aa6:	86ce                	mv	a3,s3
    80005aa8:	f1840613          	add	a2,s0,-232
    80005aac:	4581                	li	a1,0
    80005aae:	854a                	mv	a0,s2
    80005ab0:	ffffe097          	auipc	ra,0xffffe
    80005ab4:	3bc080e7          	jalr	956(ra) # 80003e6c <readi>
    80005ab8:	47c1                	li	a5,16
    80005aba:	00f51b63          	bne	a0,a5,80005ad0 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005abe:	f1845783          	lhu	a5,-232(s0)
    80005ac2:	e7a1                	bnez	a5,80005b0a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ac4:	29c1                	addw	s3,s3,16
    80005ac6:	04c92783          	lw	a5,76(s2)
    80005aca:	fcf9ede3          	bltu	s3,a5,80005aa4 <sys_unlink+0x140>
    80005ace:	b781                	j	80005a0e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005ad0:	00003517          	auipc	a0,0x3
    80005ad4:	c7050513          	add	a0,a0,-912 # 80008740 <syscalls+0x2e0>
    80005ad8:	ffffb097          	auipc	ra,0xffffb
    80005adc:	a64080e7          	jalr	-1436(ra) # 8000053c <panic>
    panic("unlink: writei");
    80005ae0:	00003517          	auipc	a0,0x3
    80005ae4:	c7850513          	add	a0,a0,-904 # 80008758 <syscalls+0x2f8>
    80005ae8:	ffffb097          	auipc	ra,0xffffb
    80005aec:	a54080e7          	jalr	-1452(ra) # 8000053c <panic>
    dp->nlink--;
    80005af0:	04a4d783          	lhu	a5,74(s1)
    80005af4:	37fd                	addw	a5,a5,-1
    80005af6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005afa:	8526                	mv	a0,s1
    80005afc:	ffffe097          	auipc	ra,0xffffe
    80005b00:	ff0080e7          	jalr	-16(ra) # 80003aec <iupdate>
    80005b04:	b781                	j	80005a44 <sys_unlink+0xe0>
    return -1;
    80005b06:	557d                	li	a0,-1
    80005b08:	a005                	j	80005b28 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005b0a:	854a                	mv	a0,s2
    80005b0c:	ffffe097          	auipc	ra,0xffffe
    80005b10:	30e080e7          	jalr	782(ra) # 80003e1a <iunlockput>
  iunlockput(dp);
    80005b14:	8526                	mv	a0,s1
    80005b16:	ffffe097          	auipc	ra,0xffffe
    80005b1a:	304080e7          	jalr	772(ra) # 80003e1a <iunlockput>
  end_op();
    80005b1e:	fffff097          	auipc	ra,0xfffff
    80005b22:	aba080e7          	jalr	-1350(ra) # 800045d8 <end_op>
  return -1;
    80005b26:	557d                	li	a0,-1
}
    80005b28:	70ae                	ld	ra,232(sp)
    80005b2a:	740e                	ld	s0,224(sp)
    80005b2c:	64ee                	ld	s1,216(sp)
    80005b2e:	694e                	ld	s2,208(sp)
    80005b30:	69ae                	ld	s3,200(sp)
    80005b32:	616d                	add	sp,sp,240
    80005b34:	8082                	ret

0000000080005b36 <sys_open>:

uint64
sys_open(void)
{
    80005b36:	7131                	add	sp,sp,-192
    80005b38:	fd06                	sd	ra,184(sp)
    80005b3a:	f922                	sd	s0,176(sp)
    80005b3c:	f526                	sd	s1,168(sp)
    80005b3e:	f14a                	sd	s2,160(sp)
    80005b40:	ed4e                	sd	s3,152(sp)
    80005b42:	0180                	add	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005b44:	f4c40593          	add	a1,s0,-180
    80005b48:	4505                	li	a0,1
    80005b4a:	ffffd097          	auipc	ra,0xffffd
    80005b4e:	3c2080e7          	jalr	962(ra) # 80002f0c <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005b52:	08000613          	li	a2,128
    80005b56:	f5040593          	add	a1,s0,-176
    80005b5a:	4501                	li	a0,0
    80005b5c:	ffffd097          	auipc	ra,0xffffd
    80005b60:	3f0080e7          	jalr	1008(ra) # 80002f4c <argstr>
    80005b64:	87aa                	mv	a5,a0
    return -1;
    80005b66:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005b68:	0a07c863          	bltz	a5,80005c18 <sys_open+0xe2>

  begin_op();
    80005b6c:	fffff097          	auipc	ra,0xfffff
    80005b70:	9f2080e7          	jalr	-1550(ra) # 8000455e <begin_op>

  if(omode & O_CREATE){
    80005b74:	f4c42783          	lw	a5,-180(s0)
    80005b78:	2007f793          	and	a5,a5,512
    80005b7c:	cbdd                	beqz	a5,80005c32 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    80005b7e:	4681                	li	a3,0
    80005b80:	4601                	li	a2,0
    80005b82:	4589                	li	a1,2
    80005b84:	f5040513          	add	a0,s0,-176
    80005b88:	00000097          	auipc	ra,0x0
    80005b8c:	958080e7          	jalr	-1704(ra) # 800054e0 <create>
    80005b90:	84aa                	mv	s1,a0
    if(ip == 0){
    80005b92:	c951                	beqz	a0,80005c26 <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005b94:	04449703          	lh	a4,68(s1)
    80005b98:	478d                	li	a5,3
    80005b9a:	00f71763          	bne	a4,a5,80005ba8 <sys_open+0x72>
    80005b9e:	0464d703          	lhu	a4,70(s1)
    80005ba2:	47a5                	li	a5,9
    80005ba4:	0ce7ec63          	bltu	a5,a4,80005c7c <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005ba8:	fffff097          	auipc	ra,0xfffff
    80005bac:	dbe080e7          	jalr	-578(ra) # 80004966 <filealloc>
    80005bb0:	892a                	mv	s2,a0
    80005bb2:	c56d                	beqz	a0,80005c9c <sys_open+0x166>
    80005bb4:	00000097          	auipc	ra,0x0
    80005bb8:	8ea080e7          	jalr	-1814(ra) # 8000549e <fdalloc>
    80005bbc:	89aa                	mv	s3,a0
    80005bbe:	0c054a63          	bltz	a0,80005c92 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005bc2:	04449703          	lh	a4,68(s1)
    80005bc6:	478d                	li	a5,3
    80005bc8:	0ef70563          	beq	a4,a5,80005cb2 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005bcc:	4789                	li	a5,2
    80005bce:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005bd2:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005bd6:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005bda:	f4c42783          	lw	a5,-180(s0)
    80005bde:	0017c713          	xor	a4,a5,1
    80005be2:	8b05                	and	a4,a4,1
    80005be4:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005be8:	0037f713          	and	a4,a5,3
    80005bec:	00e03733          	snez	a4,a4
    80005bf0:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005bf4:	4007f793          	and	a5,a5,1024
    80005bf8:	c791                	beqz	a5,80005c04 <sys_open+0xce>
    80005bfa:	04449703          	lh	a4,68(s1)
    80005bfe:	4789                	li	a5,2
    80005c00:	0cf70063          	beq	a4,a5,80005cc0 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80005c04:	8526                	mv	a0,s1
    80005c06:	ffffe097          	auipc	ra,0xffffe
    80005c0a:	074080e7          	jalr	116(ra) # 80003c7a <iunlock>
  end_op();
    80005c0e:	fffff097          	auipc	ra,0xfffff
    80005c12:	9ca080e7          	jalr	-1590(ra) # 800045d8 <end_op>

  return fd;
    80005c16:	854e                	mv	a0,s3
}
    80005c18:	70ea                	ld	ra,184(sp)
    80005c1a:	744a                	ld	s0,176(sp)
    80005c1c:	74aa                	ld	s1,168(sp)
    80005c1e:	790a                	ld	s2,160(sp)
    80005c20:	69ea                	ld	s3,152(sp)
    80005c22:	6129                	add	sp,sp,192
    80005c24:	8082                	ret
      end_op();
    80005c26:	fffff097          	auipc	ra,0xfffff
    80005c2a:	9b2080e7          	jalr	-1614(ra) # 800045d8 <end_op>
      return -1;
    80005c2e:	557d                	li	a0,-1
    80005c30:	b7e5                	j	80005c18 <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005c32:	f5040513          	add	a0,s0,-176
    80005c36:	ffffe097          	auipc	ra,0xffffe
    80005c3a:	728080e7          	jalr	1832(ra) # 8000435e <namei>
    80005c3e:	84aa                	mv	s1,a0
    80005c40:	c905                	beqz	a0,80005c70 <sys_open+0x13a>
    ilock(ip);
    80005c42:	ffffe097          	auipc	ra,0xffffe
    80005c46:	f76080e7          	jalr	-138(ra) # 80003bb8 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005c4a:	04449703          	lh	a4,68(s1)
    80005c4e:	4785                	li	a5,1
    80005c50:	f4f712e3          	bne	a4,a5,80005b94 <sys_open+0x5e>
    80005c54:	f4c42783          	lw	a5,-180(s0)
    80005c58:	dba1                	beqz	a5,80005ba8 <sys_open+0x72>
      iunlockput(ip);
    80005c5a:	8526                	mv	a0,s1
    80005c5c:	ffffe097          	auipc	ra,0xffffe
    80005c60:	1be080e7          	jalr	446(ra) # 80003e1a <iunlockput>
      end_op();
    80005c64:	fffff097          	auipc	ra,0xfffff
    80005c68:	974080e7          	jalr	-1676(ra) # 800045d8 <end_op>
      return -1;
    80005c6c:	557d                	li	a0,-1
    80005c6e:	b76d                	j	80005c18 <sys_open+0xe2>
      end_op();
    80005c70:	fffff097          	auipc	ra,0xfffff
    80005c74:	968080e7          	jalr	-1688(ra) # 800045d8 <end_op>
      return -1;
    80005c78:	557d                	li	a0,-1
    80005c7a:	bf79                	j	80005c18 <sys_open+0xe2>
    iunlockput(ip);
    80005c7c:	8526                	mv	a0,s1
    80005c7e:	ffffe097          	auipc	ra,0xffffe
    80005c82:	19c080e7          	jalr	412(ra) # 80003e1a <iunlockput>
    end_op();
    80005c86:	fffff097          	auipc	ra,0xfffff
    80005c8a:	952080e7          	jalr	-1710(ra) # 800045d8 <end_op>
    return -1;
    80005c8e:	557d                	li	a0,-1
    80005c90:	b761                	j	80005c18 <sys_open+0xe2>
      fileclose(f);
    80005c92:	854a                	mv	a0,s2
    80005c94:	fffff097          	auipc	ra,0xfffff
    80005c98:	d8e080e7          	jalr	-626(ra) # 80004a22 <fileclose>
    iunlockput(ip);
    80005c9c:	8526                	mv	a0,s1
    80005c9e:	ffffe097          	auipc	ra,0xffffe
    80005ca2:	17c080e7          	jalr	380(ra) # 80003e1a <iunlockput>
    end_op();
    80005ca6:	fffff097          	auipc	ra,0xfffff
    80005caa:	932080e7          	jalr	-1742(ra) # 800045d8 <end_op>
    return -1;
    80005cae:	557d                	li	a0,-1
    80005cb0:	b7a5                	j	80005c18 <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005cb2:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005cb6:	04649783          	lh	a5,70(s1)
    80005cba:	02f91223          	sh	a5,36(s2)
    80005cbe:	bf21                	j	80005bd6 <sys_open+0xa0>
    itrunc(ip);
    80005cc0:	8526                	mv	a0,s1
    80005cc2:	ffffe097          	auipc	ra,0xffffe
    80005cc6:	004080e7          	jalr	4(ra) # 80003cc6 <itrunc>
    80005cca:	bf2d                	j	80005c04 <sys_open+0xce>

0000000080005ccc <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005ccc:	7175                	add	sp,sp,-144
    80005cce:	e506                	sd	ra,136(sp)
    80005cd0:	e122                	sd	s0,128(sp)
    80005cd2:	0900                	add	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005cd4:	fffff097          	auipc	ra,0xfffff
    80005cd8:	88a080e7          	jalr	-1910(ra) # 8000455e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005cdc:	08000613          	li	a2,128
    80005ce0:	f7040593          	add	a1,s0,-144
    80005ce4:	4501                	li	a0,0
    80005ce6:	ffffd097          	auipc	ra,0xffffd
    80005cea:	266080e7          	jalr	614(ra) # 80002f4c <argstr>
    80005cee:	02054963          	bltz	a0,80005d20 <sys_mkdir+0x54>
    80005cf2:	4681                	li	a3,0
    80005cf4:	4601                	li	a2,0
    80005cf6:	4585                	li	a1,1
    80005cf8:	f7040513          	add	a0,s0,-144
    80005cfc:	fffff097          	auipc	ra,0xfffff
    80005d00:	7e4080e7          	jalr	2020(ra) # 800054e0 <create>
    80005d04:	cd11                	beqz	a0,80005d20 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d06:	ffffe097          	auipc	ra,0xffffe
    80005d0a:	114080e7          	jalr	276(ra) # 80003e1a <iunlockput>
  end_op();
    80005d0e:	fffff097          	auipc	ra,0xfffff
    80005d12:	8ca080e7          	jalr	-1846(ra) # 800045d8 <end_op>
  return 0;
    80005d16:	4501                	li	a0,0
}
    80005d18:	60aa                	ld	ra,136(sp)
    80005d1a:	640a                	ld	s0,128(sp)
    80005d1c:	6149                	add	sp,sp,144
    80005d1e:	8082                	ret
    end_op();
    80005d20:	fffff097          	auipc	ra,0xfffff
    80005d24:	8b8080e7          	jalr	-1864(ra) # 800045d8 <end_op>
    return -1;
    80005d28:	557d                	li	a0,-1
    80005d2a:	b7fd                	j	80005d18 <sys_mkdir+0x4c>

0000000080005d2c <sys_mknod>:

uint64
sys_mknod(void)
{
    80005d2c:	7135                	add	sp,sp,-160
    80005d2e:	ed06                	sd	ra,152(sp)
    80005d30:	e922                	sd	s0,144(sp)
    80005d32:	1100                	add	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005d34:	fffff097          	auipc	ra,0xfffff
    80005d38:	82a080e7          	jalr	-2006(ra) # 8000455e <begin_op>
  argint(1, &major);
    80005d3c:	f6c40593          	add	a1,s0,-148
    80005d40:	4505                	li	a0,1
    80005d42:	ffffd097          	auipc	ra,0xffffd
    80005d46:	1ca080e7          	jalr	458(ra) # 80002f0c <argint>
  argint(2, &minor);
    80005d4a:	f6840593          	add	a1,s0,-152
    80005d4e:	4509                	li	a0,2
    80005d50:	ffffd097          	auipc	ra,0xffffd
    80005d54:	1bc080e7          	jalr	444(ra) # 80002f0c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d58:	08000613          	li	a2,128
    80005d5c:	f7040593          	add	a1,s0,-144
    80005d60:	4501                	li	a0,0
    80005d62:	ffffd097          	auipc	ra,0xffffd
    80005d66:	1ea080e7          	jalr	490(ra) # 80002f4c <argstr>
    80005d6a:	02054b63          	bltz	a0,80005da0 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005d6e:	f6841683          	lh	a3,-152(s0)
    80005d72:	f6c41603          	lh	a2,-148(s0)
    80005d76:	458d                	li	a1,3
    80005d78:	f7040513          	add	a0,s0,-144
    80005d7c:	fffff097          	auipc	ra,0xfffff
    80005d80:	764080e7          	jalr	1892(ra) # 800054e0 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d84:	cd11                	beqz	a0,80005da0 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d86:	ffffe097          	auipc	ra,0xffffe
    80005d8a:	094080e7          	jalr	148(ra) # 80003e1a <iunlockput>
  end_op();
    80005d8e:	fffff097          	auipc	ra,0xfffff
    80005d92:	84a080e7          	jalr	-1974(ra) # 800045d8 <end_op>
  return 0;
    80005d96:	4501                	li	a0,0
}
    80005d98:	60ea                	ld	ra,152(sp)
    80005d9a:	644a                	ld	s0,144(sp)
    80005d9c:	610d                	add	sp,sp,160
    80005d9e:	8082                	ret
    end_op();
    80005da0:	fffff097          	auipc	ra,0xfffff
    80005da4:	838080e7          	jalr	-1992(ra) # 800045d8 <end_op>
    return -1;
    80005da8:	557d                	li	a0,-1
    80005daa:	b7fd                	j	80005d98 <sys_mknod+0x6c>

0000000080005dac <sys_chdir>:

uint64
sys_chdir(void)
{
    80005dac:	7135                	add	sp,sp,-160
    80005dae:	ed06                	sd	ra,152(sp)
    80005db0:	e922                	sd	s0,144(sp)
    80005db2:	e526                	sd	s1,136(sp)
    80005db4:	e14a                	sd	s2,128(sp)
    80005db6:	1100                	add	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005db8:	ffffc097          	auipc	ra,0xffffc
    80005dbc:	c18080e7          	jalr	-1000(ra) # 800019d0 <myproc>
    80005dc0:	892a                	mv	s2,a0
  
  begin_op();
    80005dc2:	ffffe097          	auipc	ra,0xffffe
    80005dc6:	79c080e7          	jalr	1948(ra) # 8000455e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005dca:	08000613          	li	a2,128
    80005dce:	f6040593          	add	a1,s0,-160
    80005dd2:	4501                	li	a0,0
    80005dd4:	ffffd097          	auipc	ra,0xffffd
    80005dd8:	178080e7          	jalr	376(ra) # 80002f4c <argstr>
    80005ddc:	04054b63          	bltz	a0,80005e32 <sys_chdir+0x86>
    80005de0:	f6040513          	add	a0,s0,-160
    80005de4:	ffffe097          	auipc	ra,0xffffe
    80005de8:	57a080e7          	jalr	1402(ra) # 8000435e <namei>
    80005dec:	84aa                	mv	s1,a0
    80005dee:	c131                	beqz	a0,80005e32 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005df0:	ffffe097          	auipc	ra,0xffffe
    80005df4:	dc8080e7          	jalr	-568(ra) # 80003bb8 <ilock>
  if(ip->type != T_DIR){
    80005df8:	04449703          	lh	a4,68(s1)
    80005dfc:	4785                	li	a5,1
    80005dfe:	04f71063          	bne	a4,a5,80005e3e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005e02:	8526                	mv	a0,s1
    80005e04:	ffffe097          	auipc	ra,0xffffe
    80005e08:	e76080e7          	jalr	-394(ra) # 80003c7a <iunlock>
  iput(p->cwd);
    80005e0c:	15093503          	ld	a0,336(s2)
    80005e10:	ffffe097          	auipc	ra,0xffffe
    80005e14:	f62080e7          	jalr	-158(ra) # 80003d72 <iput>
  end_op();
    80005e18:	ffffe097          	auipc	ra,0xffffe
    80005e1c:	7c0080e7          	jalr	1984(ra) # 800045d8 <end_op>
  p->cwd = ip;
    80005e20:	14993823          	sd	s1,336(s2)
  return 0;
    80005e24:	4501                	li	a0,0
}
    80005e26:	60ea                	ld	ra,152(sp)
    80005e28:	644a                	ld	s0,144(sp)
    80005e2a:	64aa                	ld	s1,136(sp)
    80005e2c:	690a                	ld	s2,128(sp)
    80005e2e:	610d                	add	sp,sp,160
    80005e30:	8082                	ret
    end_op();
    80005e32:	ffffe097          	auipc	ra,0xffffe
    80005e36:	7a6080e7          	jalr	1958(ra) # 800045d8 <end_op>
    return -1;
    80005e3a:	557d                	li	a0,-1
    80005e3c:	b7ed                	j	80005e26 <sys_chdir+0x7a>
    iunlockput(ip);
    80005e3e:	8526                	mv	a0,s1
    80005e40:	ffffe097          	auipc	ra,0xffffe
    80005e44:	fda080e7          	jalr	-38(ra) # 80003e1a <iunlockput>
    end_op();
    80005e48:	ffffe097          	auipc	ra,0xffffe
    80005e4c:	790080e7          	jalr	1936(ra) # 800045d8 <end_op>
    return -1;
    80005e50:	557d                	li	a0,-1
    80005e52:	bfd1                	j	80005e26 <sys_chdir+0x7a>

0000000080005e54 <sys_exec>:

uint64
sys_exec(void)
{
    80005e54:	7121                	add	sp,sp,-448
    80005e56:	ff06                	sd	ra,440(sp)
    80005e58:	fb22                	sd	s0,432(sp)
    80005e5a:	f726                	sd	s1,424(sp)
    80005e5c:	f34a                	sd	s2,416(sp)
    80005e5e:	ef4e                	sd	s3,408(sp)
    80005e60:	eb52                	sd	s4,400(sp)
    80005e62:	0380                	add	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005e64:	e4840593          	add	a1,s0,-440
    80005e68:	4505                	li	a0,1
    80005e6a:	ffffd097          	auipc	ra,0xffffd
    80005e6e:	0c2080e7          	jalr	194(ra) # 80002f2c <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005e72:	08000613          	li	a2,128
    80005e76:	f5040593          	add	a1,s0,-176
    80005e7a:	4501                	li	a0,0
    80005e7c:	ffffd097          	auipc	ra,0xffffd
    80005e80:	0d0080e7          	jalr	208(ra) # 80002f4c <argstr>
    80005e84:	87aa                	mv	a5,a0
    return -1;
    80005e86:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005e88:	0c07c263          	bltz	a5,80005f4c <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005e8c:	10000613          	li	a2,256
    80005e90:	4581                	li	a1,0
    80005e92:	e5040513          	add	a0,s0,-432
    80005e96:	ffffb097          	auipc	ra,0xffffb
    80005e9a:	e38080e7          	jalr	-456(ra) # 80000cce <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005e9e:	e5040493          	add	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005ea2:	89a6                	mv	s3,s1
    80005ea4:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ea6:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005eaa:	00391513          	sll	a0,s2,0x3
    80005eae:	e4040593          	add	a1,s0,-448
    80005eb2:	e4843783          	ld	a5,-440(s0)
    80005eb6:	953e                	add	a0,a0,a5
    80005eb8:	ffffd097          	auipc	ra,0xffffd
    80005ebc:	fb6080e7          	jalr	-74(ra) # 80002e6e <fetchaddr>
    80005ec0:	02054a63          	bltz	a0,80005ef4 <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80005ec4:	e4043783          	ld	a5,-448(s0)
    80005ec8:	c3b9                	beqz	a5,80005f0e <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005eca:	ffffb097          	auipc	ra,0xffffb
    80005ece:	c18080e7          	jalr	-1000(ra) # 80000ae2 <kalloc>
    80005ed2:	85aa                	mv	a1,a0
    80005ed4:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ed8:	cd11                	beqz	a0,80005ef4 <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005eda:	6605                	lui	a2,0x1
    80005edc:	e4043503          	ld	a0,-448(s0)
    80005ee0:	ffffd097          	auipc	ra,0xffffd
    80005ee4:	fe0080e7          	jalr	-32(ra) # 80002ec0 <fetchstr>
    80005ee8:	00054663          	bltz	a0,80005ef4 <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005eec:	0905                	add	s2,s2,1
    80005eee:	09a1                	add	s3,s3,8
    80005ef0:	fb491de3          	bne	s2,s4,80005eaa <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ef4:	f5040913          	add	s2,s0,-176
    80005ef8:	6088                	ld	a0,0(s1)
    80005efa:	c921                	beqz	a0,80005f4a <sys_exec+0xf6>
    kfree(argv[i]);
    80005efc:	ffffb097          	auipc	ra,0xffffb
    80005f00:	ae8080e7          	jalr	-1304(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f04:	04a1                	add	s1,s1,8
    80005f06:	ff2499e3          	bne	s1,s2,80005ef8 <sys_exec+0xa4>
  return -1;
    80005f0a:	557d                	li	a0,-1
    80005f0c:	a081                	j	80005f4c <sys_exec+0xf8>
      argv[i] = 0;
    80005f0e:	0009079b          	sext.w	a5,s2
    80005f12:	078e                	sll	a5,a5,0x3
    80005f14:	fd078793          	add	a5,a5,-48
    80005f18:	97a2                	add	a5,a5,s0
    80005f1a:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005f1e:	e5040593          	add	a1,s0,-432
    80005f22:	f5040513          	add	a0,s0,-176
    80005f26:	fffff097          	auipc	ra,0xfffff
    80005f2a:	172080e7          	jalr	370(ra) # 80005098 <exec>
    80005f2e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f30:	f5040993          	add	s3,s0,-176
    80005f34:	6088                	ld	a0,0(s1)
    80005f36:	c901                	beqz	a0,80005f46 <sys_exec+0xf2>
    kfree(argv[i]);
    80005f38:	ffffb097          	auipc	ra,0xffffb
    80005f3c:	aac080e7          	jalr	-1364(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f40:	04a1                	add	s1,s1,8
    80005f42:	ff3499e3          	bne	s1,s3,80005f34 <sys_exec+0xe0>
  return ret;
    80005f46:	854a                	mv	a0,s2
    80005f48:	a011                	j	80005f4c <sys_exec+0xf8>
  return -1;
    80005f4a:	557d                	li	a0,-1
}
    80005f4c:	70fa                	ld	ra,440(sp)
    80005f4e:	745a                	ld	s0,432(sp)
    80005f50:	74ba                	ld	s1,424(sp)
    80005f52:	791a                	ld	s2,416(sp)
    80005f54:	69fa                	ld	s3,408(sp)
    80005f56:	6a5a                	ld	s4,400(sp)
    80005f58:	6139                	add	sp,sp,448
    80005f5a:	8082                	ret

0000000080005f5c <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f5c:	7139                	add	sp,sp,-64
    80005f5e:	fc06                	sd	ra,56(sp)
    80005f60:	f822                	sd	s0,48(sp)
    80005f62:	f426                	sd	s1,40(sp)
    80005f64:	0080                	add	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f66:	ffffc097          	auipc	ra,0xffffc
    80005f6a:	a6a080e7          	jalr	-1430(ra) # 800019d0 <myproc>
    80005f6e:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005f70:	fd840593          	add	a1,s0,-40
    80005f74:	4501                	li	a0,0
    80005f76:	ffffd097          	auipc	ra,0xffffd
    80005f7a:	fb6080e7          	jalr	-74(ra) # 80002f2c <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005f7e:	fc840593          	add	a1,s0,-56
    80005f82:	fd040513          	add	a0,s0,-48
    80005f86:	fffff097          	auipc	ra,0xfffff
    80005f8a:	dc8080e7          	jalr	-568(ra) # 80004d4e <pipealloc>
    return -1;
    80005f8e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005f90:	0c054463          	bltz	a0,80006058 <sys_pipe+0xfc>
  fd0 = -1;
    80005f94:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005f98:	fd043503          	ld	a0,-48(s0)
    80005f9c:	fffff097          	auipc	ra,0xfffff
    80005fa0:	502080e7          	jalr	1282(ra) # 8000549e <fdalloc>
    80005fa4:	fca42223          	sw	a0,-60(s0)
    80005fa8:	08054b63          	bltz	a0,8000603e <sys_pipe+0xe2>
    80005fac:	fc843503          	ld	a0,-56(s0)
    80005fb0:	fffff097          	auipc	ra,0xfffff
    80005fb4:	4ee080e7          	jalr	1262(ra) # 8000549e <fdalloc>
    80005fb8:	fca42023          	sw	a0,-64(s0)
    80005fbc:	06054863          	bltz	a0,8000602c <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fc0:	4691                	li	a3,4
    80005fc2:	fc440613          	add	a2,s0,-60
    80005fc6:	fd843583          	ld	a1,-40(s0)
    80005fca:	68a8                	ld	a0,80(s1)
    80005fcc:	ffffb097          	auipc	ra,0xffffb
    80005fd0:	654080e7          	jalr	1620(ra) # 80001620 <copyout>
    80005fd4:	02054063          	bltz	a0,80005ff4 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005fd8:	4691                	li	a3,4
    80005fda:	fc040613          	add	a2,s0,-64
    80005fde:	fd843583          	ld	a1,-40(s0)
    80005fe2:	0591                	add	a1,a1,4
    80005fe4:	68a8                	ld	a0,80(s1)
    80005fe6:	ffffb097          	auipc	ra,0xffffb
    80005fea:	63a080e7          	jalr	1594(ra) # 80001620 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005fee:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ff0:	06055463          	bgez	a0,80006058 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005ff4:	fc442783          	lw	a5,-60(s0)
    80005ff8:	07e9                	add	a5,a5,26
    80005ffa:	078e                	sll	a5,a5,0x3
    80005ffc:	97a6                	add	a5,a5,s1
    80005ffe:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006002:	fc042783          	lw	a5,-64(s0)
    80006006:	07e9                	add	a5,a5,26
    80006008:	078e                	sll	a5,a5,0x3
    8000600a:	94be                	add	s1,s1,a5
    8000600c:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006010:	fd043503          	ld	a0,-48(s0)
    80006014:	fffff097          	auipc	ra,0xfffff
    80006018:	a0e080e7          	jalr	-1522(ra) # 80004a22 <fileclose>
    fileclose(wf);
    8000601c:	fc843503          	ld	a0,-56(s0)
    80006020:	fffff097          	auipc	ra,0xfffff
    80006024:	a02080e7          	jalr	-1534(ra) # 80004a22 <fileclose>
    return -1;
    80006028:	57fd                	li	a5,-1
    8000602a:	a03d                	j	80006058 <sys_pipe+0xfc>
    if(fd0 >= 0)
    8000602c:	fc442783          	lw	a5,-60(s0)
    80006030:	0007c763          	bltz	a5,8000603e <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80006034:	07e9                	add	a5,a5,26
    80006036:	078e                	sll	a5,a5,0x3
    80006038:	97a6                	add	a5,a5,s1
    8000603a:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    8000603e:	fd043503          	ld	a0,-48(s0)
    80006042:	fffff097          	auipc	ra,0xfffff
    80006046:	9e0080e7          	jalr	-1568(ra) # 80004a22 <fileclose>
    fileclose(wf);
    8000604a:	fc843503          	ld	a0,-56(s0)
    8000604e:	fffff097          	auipc	ra,0xfffff
    80006052:	9d4080e7          	jalr	-1580(ra) # 80004a22 <fileclose>
    return -1;
    80006056:	57fd                	li	a5,-1
}
    80006058:	853e                	mv	a0,a5
    8000605a:	70e2                	ld	ra,56(sp)
    8000605c:	7442                	ld	s0,48(sp)
    8000605e:	74a2                	ld	s1,40(sp)
    80006060:	6121                	add	sp,sp,64
    80006062:	8082                	ret
	...

0000000080006070 <kernelvec>:
    80006070:	7111                	add	sp,sp,-256
    80006072:	e006                	sd	ra,0(sp)
    80006074:	e40a                	sd	sp,8(sp)
    80006076:	e80e                	sd	gp,16(sp)
    80006078:	ec12                	sd	tp,24(sp)
    8000607a:	f016                	sd	t0,32(sp)
    8000607c:	f41a                	sd	t1,40(sp)
    8000607e:	f81e                	sd	t2,48(sp)
    80006080:	fc22                	sd	s0,56(sp)
    80006082:	e0a6                	sd	s1,64(sp)
    80006084:	e4aa                	sd	a0,72(sp)
    80006086:	e8ae                	sd	a1,80(sp)
    80006088:	ecb2                	sd	a2,88(sp)
    8000608a:	f0b6                	sd	a3,96(sp)
    8000608c:	f4ba                	sd	a4,104(sp)
    8000608e:	f8be                	sd	a5,112(sp)
    80006090:	fcc2                	sd	a6,120(sp)
    80006092:	e146                	sd	a7,128(sp)
    80006094:	e54a                	sd	s2,136(sp)
    80006096:	e94e                	sd	s3,144(sp)
    80006098:	ed52                	sd	s4,152(sp)
    8000609a:	f156                	sd	s5,160(sp)
    8000609c:	f55a                	sd	s6,168(sp)
    8000609e:	f95e                	sd	s7,176(sp)
    800060a0:	fd62                	sd	s8,184(sp)
    800060a2:	e1e6                	sd	s9,192(sp)
    800060a4:	e5ea                	sd	s10,200(sp)
    800060a6:	e9ee                	sd	s11,208(sp)
    800060a8:	edf2                	sd	t3,216(sp)
    800060aa:	f1f6                	sd	t4,224(sp)
    800060ac:	f5fa                	sd	t5,232(sp)
    800060ae:	f9fe                	sd	t6,240(sp)
    800060b0:	c8bfc0ef          	jal	80002d3a <kerneltrap>
    800060b4:	6082                	ld	ra,0(sp)
    800060b6:	6122                	ld	sp,8(sp)
    800060b8:	61c2                	ld	gp,16(sp)
    800060ba:	7282                	ld	t0,32(sp)
    800060bc:	7322                	ld	t1,40(sp)
    800060be:	73c2                	ld	t2,48(sp)
    800060c0:	7462                	ld	s0,56(sp)
    800060c2:	6486                	ld	s1,64(sp)
    800060c4:	6526                	ld	a0,72(sp)
    800060c6:	65c6                	ld	a1,80(sp)
    800060c8:	6666                	ld	a2,88(sp)
    800060ca:	7686                	ld	a3,96(sp)
    800060cc:	7726                	ld	a4,104(sp)
    800060ce:	77c6                	ld	a5,112(sp)
    800060d0:	7866                	ld	a6,120(sp)
    800060d2:	688a                	ld	a7,128(sp)
    800060d4:	692a                	ld	s2,136(sp)
    800060d6:	69ca                	ld	s3,144(sp)
    800060d8:	6a6a                	ld	s4,152(sp)
    800060da:	7a8a                	ld	s5,160(sp)
    800060dc:	7b2a                	ld	s6,168(sp)
    800060de:	7bca                	ld	s7,176(sp)
    800060e0:	7c6a                	ld	s8,184(sp)
    800060e2:	6c8e                	ld	s9,192(sp)
    800060e4:	6d2e                	ld	s10,200(sp)
    800060e6:	6dce                	ld	s11,208(sp)
    800060e8:	6e6e                	ld	t3,216(sp)
    800060ea:	7e8e                	ld	t4,224(sp)
    800060ec:	7f2e                	ld	t5,232(sp)
    800060ee:	7fce                	ld	t6,240(sp)
    800060f0:	6111                	add	sp,sp,256
    800060f2:	10200073          	sret
    800060f6:	00000013          	nop
    800060fa:	00000013          	nop
    800060fe:	0001                	nop

0000000080006100 <timervec>:
    80006100:	34051573          	csrrw	a0,mscratch,a0
    80006104:	e10c                	sd	a1,0(a0)
    80006106:	e510                	sd	a2,8(a0)
    80006108:	e914                	sd	a3,16(a0)
    8000610a:	6d0c                	ld	a1,24(a0)
    8000610c:	7110                	ld	a2,32(a0)
    8000610e:	6194                	ld	a3,0(a1)
    80006110:	96b2                	add	a3,a3,a2
    80006112:	e194                	sd	a3,0(a1)
    80006114:	4589                	li	a1,2
    80006116:	14459073          	csrw	sip,a1
    8000611a:	6914                	ld	a3,16(a0)
    8000611c:	6510                	ld	a2,8(a0)
    8000611e:	610c                	ld	a1,0(a0)
    80006120:	34051573          	csrrw	a0,mscratch,a0
    80006124:	30200073          	mret
	...

000000008000612a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000612a:	1141                	add	sp,sp,-16
    8000612c:	e422                	sd	s0,8(sp)
    8000612e:	0800                	add	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006130:	0c0007b7          	lui	a5,0xc000
    80006134:	4705                	li	a4,1
    80006136:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006138:	c3d8                	sw	a4,4(a5)
}
    8000613a:	6422                	ld	s0,8(sp)
    8000613c:	0141                	add	sp,sp,16
    8000613e:	8082                	ret

0000000080006140 <plicinithart>:

void
plicinithart(void)
{
    80006140:	1141                	add	sp,sp,-16
    80006142:	e406                	sd	ra,8(sp)
    80006144:	e022                	sd	s0,0(sp)
    80006146:	0800                	add	s0,sp,16
  int hart = cpuid();
    80006148:	ffffc097          	auipc	ra,0xffffc
    8000614c:	85c080e7          	jalr	-1956(ra) # 800019a4 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006150:	0085171b          	sllw	a4,a0,0x8
    80006154:	0c0027b7          	lui	a5,0xc002
    80006158:	97ba                	add	a5,a5,a4
    8000615a:	40200713          	li	a4,1026
    8000615e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006162:	00d5151b          	sllw	a0,a0,0xd
    80006166:	0c2017b7          	lui	a5,0xc201
    8000616a:	97aa                	add	a5,a5,a0
    8000616c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006170:	60a2                	ld	ra,8(sp)
    80006172:	6402                	ld	s0,0(sp)
    80006174:	0141                	add	sp,sp,16
    80006176:	8082                	ret

0000000080006178 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006178:	1141                	add	sp,sp,-16
    8000617a:	e406                	sd	ra,8(sp)
    8000617c:	e022                	sd	s0,0(sp)
    8000617e:	0800                	add	s0,sp,16
  int hart = cpuid();
    80006180:	ffffc097          	auipc	ra,0xffffc
    80006184:	824080e7          	jalr	-2012(ra) # 800019a4 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006188:	00d5151b          	sllw	a0,a0,0xd
    8000618c:	0c2017b7          	lui	a5,0xc201
    80006190:	97aa                	add	a5,a5,a0
  return irq;
}
    80006192:	43c8                	lw	a0,4(a5)
    80006194:	60a2                	ld	ra,8(sp)
    80006196:	6402                	ld	s0,0(sp)
    80006198:	0141                	add	sp,sp,16
    8000619a:	8082                	ret

000000008000619c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000619c:	1101                	add	sp,sp,-32
    8000619e:	ec06                	sd	ra,24(sp)
    800061a0:	e822                	sd	s0,16(sp)
    800061a2:	e426                	sd	s1,8(sp)
    800061a4:	1000                	add	s0,sp,32
    800061a6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800061a8:	ffffb097          	auipc	ra,0xffffb
    800061ac:	7fc080e7          	jalr	2044(ra) # 800019a4 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800061b0:	00d5151b          	sllw	a0,a0,0xd
    800061b4:	0c2017b7          	lui	a5,0xc201
    800061b8:	97aa                	add	a5,a5,a0
    800061ba:	c3c4                	sw	s1,4(a5)
}
    800061bc:	60e2                	ld	ra,24(sp)
    800061be:	6442                	ld	s0,16(sp)
    800061c0:	64a2                	ld	s1,8(sp)
    800061c2:	6105                	add	sp,sp,32
    800061c4:	8082                	ret

00000000800061c6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800061c6:	1141                	add	sp,sp,-16
    800061c8:	e406                	sd	ra,8(sp)
    800061ca:	e022                	sd	s0,0(sp)
    800061cc:	0800                	add	s0,sp,16
  if(i >= NUM)
    800061ce:	479d                	li	a5,7
    800061d0:	04a7cc63          	blt	a5,a0,80006228 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800061d4:	0001c797          	auipc	a5,0x1c
    800061d8:	25c78793          	add	a5,a5,604 # 80022430 <disk>
    800061dc:	97aa                	add	a5,a5,a0
    800061de:	0187c783          	lbu	a5,24(a5)
    800061e2:	ebb9                	bnez	a5,80006238 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800061e4:	00451693          	sll	a3,a0,0x4
    800061e8:	0001c797          	auipc	a5,0x1c
    800061ec:	24878793          	add	a5,a5,584 # 80022430 <disk>
    800061f0:	6398                	ld	a4,0(a5)
    800061f2:	9736                	add	a4,a4,a3
    800061f4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    800061f8:	6398                	ld	a4,0(a5)
    800061fa:	9736                	add	a4,a4,a3
    800061fc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006200:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006204:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006208:	97aa                	add	a5,a5,a0
    8000620a:	4705                	li	a4,1
    8000620c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006210:	0001c517          	auipc	a0,0x1c
    80006214:	23850513          	add	a0,a0,568 # 80022448 <disk+0x18>
    80006218:	ffffc097          	auipc	ra,0xffffc
    8000621c:	09e080e7          	jalr	158(ra) # 800022b6 <wakeup>
}
    80006220:	60a2                	ld	ra,8(sp)
    80006222:	6402                	ld	s0,0(sp)
    80006224:	0141                	add	sp,sp,16
    80006226:	8082                	ret
    panic("free_desc 1");
    80006228:	00002517          	auipc	a0,0x2
    8000622c:	54050513          	add	a0,a0,1344 # 80008768 <syscalls+0x308>
    80006230:	ffffa097          	auipc	ra,0xffffa
    80006234:	30c080e7          	jalr	780(ra) # 8000053c <panic>
    panic("free_desc 2");
    80006238:	00002517          	auipc	a0,0x2
    8000623c:	54050513          	add	a0,a0,1344 # 80008778 <syscalls+0x318>
    80006240:	ffffa097          	auipc	ra,0xffffa
    80006244:	2fc080e7          	jalr	764(ra) # 8000053c <panic>

0000000080006248 <virtio_disk_init>:
{
    80006248:	1101                	add	sp,sp,-32
    8000624a:	ec06                	sd	ra,24(sp)
    8000624c:	e822                	sd	s0,16(sp)
    8000624e:	e426                	sd	s1,8(sp)
    80006250:	e04a                	sd	s2,0(sp)
    80006252:	1000                	add	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006254:	00002597          	auipc	a1,0x2
    80006258:	53458593          	add	a1,a1,1332 # 80008788 <syscalls+0x328>
    8000625c:	0001c517          	auipc	a0,0x1c
    80006260:	2fc50513          	add	a0,a0,764 # 80022558 <disk+0x128>
    80006264:	ffffb097          	auipc	ra,0xffffb
    80006268:	8de080e7          	jalr	-1826(ra) # 80000b42 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000626c:	100017b7          	lui	a5,0x10001
    80006270:	4398                	lw	a4,0(a5)
    80006272:	2701                	sext.w	a4,a4
    80006274:	747277b7          	lui	a5,0x74727
    80006278:	97678793          	add	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000627c:	14f71b63          	bne	a4,a5,800063d2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006280:	100017b7          	lui	a5,0x10001
    80006284:	43dc                	lw	a5,4(a5)
    80006286:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006288:	4709                	li	a4,2
    8000628a:	14e79463          	bne	a5,a4,800063d2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000628e:	100017b7          	lui	a5,0x10001
    80006292:	479c                	lw	a5,8(a5)
    80006294:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006296:	12e79e63          	bne	a5,a4,800063d2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000629a:	100017b7          	lui	a5,0x10001
    8000629e:	47d8                	lw	a4,12(a5)
    800062a0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062a2:	554d47b7          	lui	a5,0x554d4
    800062a6:	55178793          	add	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800062aa:	12f71463          	bne	a4,a5,800063d2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    800062ae:	100017b7          	lui	a5,0x10001
    800062b2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800062b6:	4705                	li	a4,1
    800062b8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062ba:	470d                	li	a4,3
    800062bc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800062be:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800062c0:	c7ffe6b7          	lui	a3,0xc7ffe
    800062c4:	75f68693          	add	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc1ef>
    800062c8:	8f75                	and	a4,a4,a3
    800062ca:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062cc:	472d                	li	a4,11
    800062ce:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800062d0:	5bbc                	lw	a5,112(a5)
    800062d2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800062d6:	8ba1                	and	a5,a5,8
    800062d8:	10078563          	beqz	a5,800063e2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800062dc:	100017b7          	lui	a5,0x10001
    800062e0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800062e4:	43fc                	lw	a5,68(a5)
    800062e6:	2781                	sext.w	a5,a5
    800062e8:	10079563          	bnez	a5,800063f2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800062ec:	100017b7          	lui	a5,0x10001
    800062f0:	5bdc                	lw	a5,52(a5)
    800062f2:	2781                	sext.w	a5,a5
  if(max == 0)
    800062f4:	10078763          	beqz	a5,80006402 <virtio_disk_init+0x1ba>
  if(max < NUM)
    800062f8:	471d                	li	a4,7
    800062fa:	10f77c63          	bgeu	a4,a5,80006412 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    800062fe:	ffffa097          	auipc	ra,0xffffa
    80006302:	7e4080e7          	jalr	2020(ra) # 80000ae2 <kalloc>
    80006306:	0001c497          	auipc	s1,0x1c
    8000630a:	12a48493          	add	s1,s1,298 # 80022430 <disk>
    8000630e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006310:	ffffa097          	auipc	ra,0xffffa
    80006314:	7d2080e7          	jalr	2002(ra) # 80000ae2 <kalloc>
    80006318:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000631a:	ffffa097          	auipc	ra,0xffffa
    8000631e:	7c8080e7          	jalr	1992(ra) # 80000ae2 <kalloc>
    80006322:	87aa                	mv	a5,a0
    80006324:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006326:	6088                	ld	a0,0(s1)
    80006328:	cd6d                	beqz	a0,80006422 <virtio_disk_init+0x1da>
    8000632a:	0001c717          	auipc	a4,0x1c
    8000632e:	10e73703          	ld	a4,270(a4) # 80022438 <disk+0x8>
    80006332:	cb65                	beqz	a4,80006422 <virtio_disk_init+0x1da>
    80006334:	c7fd                	beqz	a5,80006422 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006336:	6605                	lui	a2,0x1
    80006338:	4581                	li	a1,0
    8000633a:	ffffb097          	auipc	ra,0xffffb
    8000633e:	994080e7          	jalr	-1644(ra) # 80000cce <memset>
  memset(disk.avail, 0, PGSIZE);
    80006342:	0001c497          	auipc	s1,0x1c
    80006346:	0ee48493          	add	s1,s1,238 # 80022430 <disk>
    8000634a:	6605                	lui	a2,0x1
    8000634c:	4581                	li	a1,0
    8000634e:	6488                	ld	a0,8(s1)
    80006350:	ffffb097          	auipc	ra,0xffffb
    80006354:	97e080e7          	jalr	-1666(ra) # 80000cce <memset>
  memset(disk.used, 0, PGSIZE);
    80006358:	6605                	lui	a2,0x1
    8000635a:	4581                	li	a1,0
    8000635c:	6888                	ld	a0,16(s1)
    8000635e:	ffffb097          	auipc	ra,0xffffb
    80006362:	970080e7          	jalr	-1680(ra) # 80000cce <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006366:	100017b7          	lui	a5,0x10001
    8000636a:	4721                	li	a4,8
    8000636c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000636e:	4098                	lw	a4,0(s1)
    80006370:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006374:	40d8                	lw	a4,4(s1)
    80006376:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000637a:	6498                	ld	a4,8(s1)
    8000637c:	0007069b          	sext.w	a3,a4
    80006380:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006384:	9701                	sra	a4,a4,0x20
    80006386:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000638a:	6898                	ld	a4,16(s1)
    8000638c:	0007069b          	sext.w	a3,a4
    80006390:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006394:	9701                	sra	a4,a4,0x20
    80006396:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000639a:	4705                	li	a4,1
    8000639c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000639e:	00e48c23          	sb	a4,24(s1)
    800063a2:	00e48ca3          	sb	a4,25(s1)
    800063a6:	00e48d23          	sb	a4,26(s1)
    800063aa:	00e48da3          	sb	a4,27(s1)
    800063ae:	00e48e23          	sb	a4,28(s1)
    800063b2:	00e48ea3          	sb	a4,29(s1)
    800063b6:	00e48f23          	sb	a4,30(s1)
    800063ba:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800063be:	00496913          	or	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800063c2:	0727a823          	sw	s2,112(a5)
}
    800063c6:	60e2                	ld	ra,24(sp)
    800063c8:	6442                	ld	s0,16(sp)
    800063ca:	64a2                	ld	s1,8(sp)
    800063cc:	6902                	ld	s2,0(sp)
    800063ce:	6105                	add	sp,sp,32
    800063d0:	8082                	ret
    panic("could not find virtio disk");
    800063d2:	00002517          	auipc	a0,0x2
    800063d6:	3c650513          	add	a0,a0,966 # 80008798 <syscalls+0x338>
    800063da:	ffffa097          	auipc	ra,0xffffa
    800063de:	162080e7          	jalr	354(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    800063e2:	00002517          	auipc	a0,0x2
    800063e6:	3d650513          	add	a0,a0,982 # 800087b8 <syscalls+0x358>
    800063ea:	ffffa097          	auipc	ra,0xffffa
    800063ee:	152080e7          	jalr	338(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    800063f2:	00002517          	auipc	a0,0x2
    800063f6:	3e650513          	add	a0,a0,998 # 800087d8 <syscalls+0x378>
    800063fa:	ffffa097          	auipc	ra,0xffffa
    800063fe:	142080e7          	jalr	322(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    80006402:	00002517          	auipc	a0,0x2
    80006406:	3f650513          	add	a0,a0,1014 # 800087f8 <syscalls+0x398>
    8000640a:	ffffa097          	auipc	ra,0xffffa
    8000640e:	132080e7          	jalr	306(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    80006412:	00002517          	auipc	a0,0x2
    80006416:	40650513          	add	a0,a0,1030 # 80008818 <syscalls+0x3b8>
    8000641a:	ffffa097          	auipc	ra,0xffffa
    8000641e:	122080e7          	jalr	290(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    80006422:	00002517          	auipc	a0,0x2
    80006426:	41650513          	add	a0,a0,1046 # 80008838 <syscalls+0x3d8>
    8000642a:	ffffa097          	auipc	ra,0xffffa
    8000642e:	112080e7          	jalr	274(ra) # 8000053c <panic>

0000000080006432 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006432:	7159                	add	sp,sp,-112
    80006434:	f486                	sd	ra,104(sp)
    80006436:	f0a2                	sd	s0,96(sp)
    80006438:	eca6                	sd	s1,88(sp)
    8000643a:	e8ca                	sd	s2,80(sp)
    8000643c:	e4ce                	sd	s3,72(sp)
    8000643e:	e0d2                	sd	s4,64(sp)
    80006440:	fc56                	sd	s5,56(sp)
    80006442:	f85a                	sd	s6,48(sp)
    80006444:	f45e                	sd	s7,40(sp)
    80006446:	f062                	sd	s8,32(sp)
    80006448:	ec66                	sd	s9,24(sp)
    8000644a:	e86a                	sd	s10,16(sp)
    8000644c:	1880                	add	s0,sp,112
    8000644e:	8a2a                	mv	s4,a0
    80006450:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006452:	00c52c83          	lw	s9,12(a0)
    80006456:	001c9c9b          	sllw	s9,s9,0x1
    8000645a:	1c82                	sll	s9,s9,0x20
    8000645c:	020cdc93          	srl	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006460:	0001c517          	auipc	a0,0x1c
    80006464:	0f850513          	add	a0,a0,248 # 80022558 <disk+0x128>
    80006468:	ffffa097          	auipc	ra,0xffffa
    8000646c:	76a080e7          	jalr	1898(ra) # 80000bd2 <acquire>
  for(int i = 0; i < 3; i++){
    80006470:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80006472:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006474:	0001cb17          	auipc	s6,0x1c
    80006478:	fbcb0b13          	add	s6,s6,-68 # 80022430 <disk>
  for(int i = 0; i < 3; i++){
    8000647c:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000647e:	0001cc17          	auipc	s8,0x1c
    80006482:	0dac0c13          	add	s8,s8,218 # 80022558 <disk+0x128>
    80006486:	a095                	j	800064ea <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80006488:	00fb0733          	add	a4,s6,a5
    8000648c:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006490:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80006492:	0207c563          	bltz	a5,800064bc <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80006496:	2605                	addw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80006498:	0591                	add	a1,a1,4
    8000649a:	05560d63          	beq	a2,s5,800064f4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    8000649e:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    800064a0:	0001c717          	auipc	a4,0x1c
    800064a4:	f9070713          	add	a4,a4,-112 # 80022430 <disk>
    800064a8:	87ca                	mv	a5,s2
    if(disk.free[i]){
    800064aa:	01874683          	lbu	a3,24(a4)
    800064ae:	fee9                	bnez	a3,80006488 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    800064b0:	2785                	addw	a5,a5,1
    800064b2:	0705                	add	a4,a4,1
    800064b4:	fe979be3          	bne	a5,s1,800064aa <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    800064b8:	57fd                	li	a5,-1
    800064ba:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    800064bc:	00c05e63          	blez	a2,800064d8 <virtio_disk_rw+0xa6>
    800064c0:	060a                	sll	a2,a2,0x2
    800064c2:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    800064c6:	0009a503          	lw	a0,0(s3)
    800064ca:	00000097          	auipc	ra,0x0
    800064ce:	cfc080e7          	jalr	-772(ra) # 800061c6 <free_desc>
      for(int j = 0; j < i; j++)
    800064d2:	0991                	add	s3,s3,4
    800064d4:	ffa999e3          	bne	s3,s10,800064c6 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800064d8:	85e2                	mv	a1,s8
    800064da:	0001c517          	auipc	a0,0x1c
    800064de:	f6e50513          	add	a0,a0,-146 # 80022448 <disk+0x18>
    800064e2:	ffffc097          	auipc	ra,0xffffc
    800064e6:	d70080e7          	jalr	-656(ra) # 80002252 <sleep>
  for(int i = 0; i < 3; i++){
    800064ea:	f9040993          	add	s3,s0,-112
{
    800064ee:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    800064f0:	864a                	mv	a2,s2
    800064f2:	b775                	j	8000649e <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800064f4:	f9042503          	lw	a0,-112(s0)
    800064f8:	00a50713          	add	a4,a0,10
    800064fc:	0712                	sll	a4,a4,0x4

  if(write)
    800064fe:	0001c797          	auipc	a5,0x1c
    80006502:	f3278793          	add	a5,a5,-206 # 80022430 <disk>
    80006506:	00e786b3          	add	a3,a5,a4
    8000650a:	01703633          	snez	a2,s7
    8000650e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006510:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006514:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006518:	f6070613          	add	a2,a4,-160
    8000651c:	6394                	ld	a3,0(a5)
    8000651e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006520:	00870593          	add	a1,a4,8
    80006524:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006526:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006528:	0007b803          	ld	a6,0(a5)
    8000652c:	9642                	add	a2,a2,a6
    8000652e:	46c1                	li	a3,16
    80006530:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006532:	4585                	li	a1,1
    80006534:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006538:	f9442683          	lw	a3,-108(s0)
    8000653c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006540:	0692                	sll	a3,a3,0x4
    80006542:	9836                	add	a6,a6,a3
    80006544:	058a0613          	add	a2,s4,88
    80006548:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000654c:	0007b803          	ld	a6,0(a5)
    80006550:	96c2                	add	a3,a3,a6
    80006552:	40000613          	li	a2,1024
    80006556:	c690                	sw	a2,8(a3)
  if(write)
    80006558:	001bb613          	seqz	a2,s7
    8000655c:	0016161b          	sllw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006560:	00166613          	or	a2,a2,1
    80006564:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006568:	f9842603          	lw	a2,-104(s0)
    8000656c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006570:	00250693          	add	a3,a0,2
    80006574:	0692                	sll	a3,a3,0x4
    80006576:	96be                	add	a3,a3,a5
    80006578:	58fd                	li	a7,-1
    8000657a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000657e:	0612                	sll	a2,a2,0x4
    80006580:	9832                	add	a6,a6,a2
    80006582:	f9070713          	add	a4,a4,-112
    80006586:	973e                	add	a4,a4,a5
    80006588:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000658c:	6398                	ld	a4,0(a5)
    8000658e:	9732                	add	a4,a4,a2
    80006590:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006592:	4609                	li	a2,2
    80006594:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006598:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000659c:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    800065a0:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800065a4:	6794                	ld	a3,8(a5)
    800065a6:	0026d703          	lhu	a4,2(a3)
    800065aa:	8b1d                	and	a4,a4,7
    800065ac:	0706                	sll	a4,a4,0x1
    800065ae:	96ba                	add	a3,a3,a4
    800065b0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    800065b4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800065b8:	6798                	ld	a4,8(a5)
    800065ba:	00275783          	lhu	a5,2(a4)
    800065be:	2785                	addw	a5,a5,1
    800065c0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800065c4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800065c8:	100017b7          	lui	a5,0x10001
    800065cc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800065d0:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    800065d4:	0001c917          	auipc	s2,0x1c
    800065d8:	f8490913          	add	s2,s2,-124 # 80022558 <disk+0x128>
  while(b->disk == 1) {
    800065dc:	4485                	li	s1,1
    800065de:	00b79c63          	bne	a5,a1,800065f6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800065e2:	85ca                	mv	a1,s2
    800065e4:	8552                	mv	a0,s4
    800065e6:	ffffc097          	auipc	ra,0xffffc
    800065ea:	c6c080e7          	jalr	-916(ra) # 80002252 <sleep>
  while(b->disk == 1) {
    800065ee:	004a2783          	lw	a5,4(s4)
    800065f2:	fe9788e3          	beq	a5,s1,800065e2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800065f6:	f9042903          	lw	s2,-112(s0)
    800065fa:	00290713          	add	a4,s2,2
    800065fe:	0712                	sll	a4,a4,0x4
    80006600:	0001c797          	auipc	a5,0x1c
    80006604:	e3078793          	add	a5,a5,-464 # 80022430 <disk>
    80006608:	97ba                	add	a5,a5,a4
    8000660a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000660e:	0001c997          	auipc	s3,0x1c
    80006612:	e2298993          	add	s3,s3,-478 # 80022430 <disk>
    80006616:	00491713          	sll	a4,s2,0x4
    8000661a:	0009b783          	ld	a5,0(s3)
    8000661e:	97ba                	add	a5,a5,a4
    80006620:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006624:	854a                	mv	a0,s2
    80006626:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000662a:	00000097          	auipc	ra,0x0
    8000662e:	b9c080e7          	jalr	-1124(ra) # 800061c6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006632:	8885                	and	s1,s1,1
    80006634:	f0ed                	bnez	s1,80006616 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006636:	0001c517          	auipc	a0,0x1c
    8000663a:	f2250513          	add	a0,a0,-222 # 80022558 <disk+0x128>
    8000663e:	ffffa097          	auipc	ra,0xffffa
    80006642:	648080e7          	jalr	1608(ra) # 80000c86 <release>
}
    80006646:	70a6                	ld	ra,104(sp)
    80006648:	7406                	ld	s0,96(sp)
    8000664a:	64e6                	ld	s1,88(sp)
    8000664c:	6946                	ld	s2,80(sp)
    8000664e:	69a6                	ld	s3,72(sp)
    80006650:	6a06                	ld	s4,64(sp)
    80006652:	7ae2                	ld	s5,56(sp)
    80006654:	7b42                	ld	s6,48(sp)
    80006656:	7ba2                	ld	s7,40(sp)
    80006658:	7c02                	ld	s8,32(sp)
    8000665a:	6ce2                	ld	s9,24(sp)
    8000665c:	6d42                	ld	s10,16(sp)
    8000665e:	6165                	add	sp,sp,112
    80006660:	8082                	ret

0000000080006662 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006662:	1101                	add	sp,sp,-32
    80006664:	ec06                	sd	ra,24(sp)
    80006666:	e822                	sd	s0,16(sp)
    80006668:	e426                	sd	s1,8(sp)
    8000666a:	1000                	add	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000666c:	0001c497          	auipc	s1,0x1c
    80006670:	dc448493          	add	s1,s1,-572 # 80022430 <disk>
    80006674:	0001c517          	auipc	a0,0x1c
    80006678:	ee450513          	add	a0,a0,-284 # 80022558 <disk+0x128>
    8000667c:	ffffa097          	auipc	ra,0xffffa
    80006680:	556080e7          	jalr	1366(ra) # 80000bd2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006684:	10001737          	lui	a4,0x10001
    80006688:	533c                	lw	a5,96(a4)
    8000668a:	8b8d                	and	a5,a5,3
    8000668c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000668e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006692:	689c                	ld	a5,16(s1)
    80006694:	0204d703          	lhu	a4,32(s1)
    80006698:	0027d783          	lhu	a5,2(a5)
    8000669c:	04f70863          	beq	a4,a5,800066ec <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800066a0:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800066a4:	6898                	ld	a4,16(s1)
    800066a6:	0204d783          	lhu	a5,32(s1)
    800066aa:	8b9d                	and	a5,a5,7
    800066ac:	078e                	sll	a5,a5,0x3
    800066ae:	97ba                	add	a5,a5,a4
    800066b0:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800066b2:	00278713          	add	a4,a5,2
    800066b6:	0712                	sll	a4,a4,0x4
    800066b8:	9726                	add	a4,a4,s1
    800066ba:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800066be:	e721                	bnez	a4,80006706 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800066c0:	0789                	add	a5,a5,2
    800066c2:	0792                	sll	a5,a5,0x4
    800066c4:	97a6                	add	a5,a5,s1
    800066c6:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800066c8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800066cc:	ffffc097          	auipc	ra,0xffffc
    800066d0:	bea080e7          	jalr	-1046(ra) # 800022b6 <wakeup>

    disk.used_idx += 1;
    800066d4:	0204d783          	lhu	a5,32(s1)
    800066d8:	2785                	addw	a5,a5,1
    800066da:	17c2                	sll	a5,a5,0x30
    800066dc:	93c1                	srl	a5,a5,0x30
    800066de:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800066e2:	6898                	ld	a4,16(s1)
    800066e4:	00275703          	lhu	a4,2(a4)
    800066e8:	faf71ce3          	bne	a4,a5,800066a0 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800066ec:	0001c517          	auipc	a0,0x1c
    800066f0:	e6c50513          	add	a0,a0,-404 # 80022558 <disk+0x128>
    800066f4:	ffffa097          	auipc	ra,0xffffa
    800066f8:	592080e7          	jalr	1426(ra) # 80000c86 <release>
}
    800066fc:	60e2                	ld	ra,24(sp)
    800066fe:	6442                	ld	s0,16(sp)
    80006700:	64a2                	ld	s1,8(sp)
    80006702:	6105                	add	sp,sp,32
    80006704:	8082                	ret
      panic("virtio_disk_intr status");
    80006706:	00002517          	auipc	a0,0x2
    8000670a:	14a50513          	add	a0,a0,330 # 80008850 <syscalls+0x3f0>
    8000670e:	ffffa097          	auipc	ra,0xffffa
    80006712:	e2e080e7          	jalr	-466(ra) # 8000053c <panic>
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
