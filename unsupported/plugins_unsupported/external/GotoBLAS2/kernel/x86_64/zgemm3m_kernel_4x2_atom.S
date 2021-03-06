/*********************************************************************/
/*                                                                   */
/*             Optimized BLAS libraries                              */
/*                     By Kazushige Goto <kgoto@tacc.utexas.edu>     */
/*                                                                   */
/* Copyright (c) The University of Texas, 2009. All rights reserved. */
/* UNIVERSITY EXPRESSLY DISCLAIMS ANY AND ALL WARRANTIES CONCERNING  */
/* THIS SOFTWARE AND DOCUMENTATION, INCLUDING ANY WARRANTIES OF      */
/* MERCHANTABILITY, FITNESS FOR ANY PARTICULAR PURPOSE,              */
/* NON-INFRINGEMENT AND WARRANTIES OF PERFORMANCE, AND ANY WARRANTY  */
/* THAT MIGHT OTHERWISE ARISE FROM COURSE OF DEALING OR USAGE OF     */
/* TRADE. NO WARRANTY IS EITHER EXPRESS OR IMPLIED WITH RESPECT TO   */
/* THE USE OF THE SOFTWARE OR DOCUMENTATION.                         */
/* Under no circumstances shall University be liable for incidental, */
/* special, indirect, direct or consequential damages or loss of     */
/* profits, interruption of business, or related expenses which may  */
/* arise from use of Software or Documentation, including but not    */
/* limited to those resulting from defects in Software and/or        */
/* Documentation, or loss or inaccuracy of data of any kind.         */
/*********************************************************************/

#define ASSEMBLER
#include "common.h"
 
#define M	%rdi
#define N	%rsi
#define K	%rdx

#define A	%rcx
#define B	%r8
#define C	%r9
#define LDC	%r10

#define I	%r11
#define J	%r12
#define AO	%r13
#define BO	%r14
#define	CO1	%r15
#define CO2	%rbx
#define BB	%rbp

#ifndef WINDOWS_ABI

#define STACKSIZE 128

#define OLD_LDC		 8 + STACKSIZE(%rsp)
#define OLD_OFFSET	16 + STACKSIZE(%rsp)

#define ALPHA_R	 48(%rsp)
#define ALPHA_I	 56(%rsp)
#define OFFSET	 64(%rsp)
#define KKK	 72(%rsp)
#define KK	 80(%rsp)

#else

#define STACKSIZE 512

#define OLD_ALPHA_I	40 + STACKSIZE(%rsp)
#define OLD_A		48 + STACKSIZE(%rsp)
#define OLD_B		56 + STACKSIZE(%rsp)
#define OLD_C		64 + STACKSIZE(%rsp)
#define OLD_LDC		72 + STACKSIZE(%rsp)
#define OLD_OFFSET	80 + STACKSIZE(%rsp)

#define ALPHA_R	 224(%rsp)
#define ALPHA_I	 232(%rsp)
#define OFFSET	 240(%rsp)
#define KK	 248(%rsp)
#define KKK	 256(%rsp)

#endif

#define PREFETCH     prefetcht0
#define PREFETCHSIZE (8 * 8 + 3)

#if defined(OS_LINUX) && defined(CORE_BARCELONA)
	.align 32768
#endif
	PROLOGUE
	PROFCODE
	
	subq	$STACKSIZE, %rsp
	movq	%rbx,  0(%rsp)
	movq	%rbp,  8(%rsp)
	movq	%r12, 16(%rsp)
	movq	%r13, 24(%rsp)
	movq	%r14, 32(%rsp)
	movq	%r15, 40(%rsp)

#ifdef WINDOWS_ABI
	movq	%rdi,    48(%rsp)
	movq	%rsi,    56(%rsp)
	movups	%xmm6,   64(%rsp)
	movups	%xmm7,   80(%rsp)
	movups	%xmm8,   96(%rsp)
	movups	%xmm9,  112(%rsp)
	movups	%xmm10, 128(%rsp)
	movups	%xmm11, 144(%rsp)
	movups	%xmm12, 160(%rsp)
	movups	%xmm13, 176(%rsp)
	movups	%xmm14, 192(%rsp)
	movups	%xmm15, 208(%rsp)

	movq	ARG1,      M
	movq	ARG2,      N
	movq	ARG3,      K
	movq	OLD_A,     A
	movq	OLD_B,     B
	movq	OLD_C,     C
	movq	OLD_LDC,   LDC

	movaps	%xmm3, %xmm0
	movsd	OLD_ALPHA_I, %xmm1

#else
	movq	OLD_LDC,   LDC
#endif

	movsd	 %xmm0, ALPHA_R
	movsd	 %xmm1, ALPHA_I
	
	salq	$ZBASE_SHIFT, LDC

	movq	N,  J
	sarq	$1, J
	jle	.L40
	ALIGN_4
	
.L10:
	movq	C, CO1
	leaq	(C, LDC, 1), CO2
	leaq	(C, LDC, 2), C

	movq	A, AO

	movq	K, %rax
	salq	$BASE_SHIFT + 1, %rax
	leaq	(B, %rax), BB
	
	movq	M,  I
	sarq	$2, I
	jle	.L20
	ALIGN_4

.L11:
	movq	B, BO

	prefetcht0	  0 * SIZE(BB)
	subq	   $-8 * SIZE, BB

	movsd	 0 * SIZE(AO), %xmm0
	xorps	%xmm2,  %xmm2
	movsd	 1 * SIZE(AO), %xmm4
	xorps	%xmm5,  %xmm5
	movsd	 2 * SIZE(AO), %xmm5
	xorps	%xmm6,  %xmm6
	xorps	%xmm7,  %xmm7

	movsd	 0 * SIZE(BO), %xmm1
	xorps	%xmm8,  %xmm8
	xorps	%xmm9,  %xmm9
	movsd	 1 * SIZE(BO), %xmm3
	xorps	%xmm10, %xmm10
	xorps	%xmm11, %xmm11

	prefetcht0     3 * SIZE(CO1)
	xorps	%xmm12, %xmm12
	xorps	%xmm13, %xmm13
	prefetcht0     3 * SIZE(CO2)
	xorps	%xmm14, %xmm14
	xorps	%xmm15, %xmm15

	movq	K, %rax
	sarq	$2, %rax
	je	.L15
	ALIGN_4

.L12:
	addsd	 %xmm2, %xmm13
	PREFETCH (PREFETCHSIZE + 0) * SIZE(AO)
	movaps	 %xmm0, %xmm2
	mulsd	 %xmm1, %xmm0

	addsd	 %xmm7, %xmm14
	movsd	 3 * SIZE(AO), %xmm7
	mulsd	 %xmm3, %xmm2
 
	addsd	 %xmm6, %xmm15
	PREFETCH ((PREFETCHSIZE) >> 1 + 0) * SIZE(BO)
	movaps	 %xmm4, %xmm6
	mulsd	 %xmm1, %xmm4

	addsd	 %xmm0, %xmm8
	movsd	 4 * SIZE(AO), %xmm0
	mulsd	 %xmm3, %xmm6

	addsd	 %xmm2, %xmm9
	movaps	 %xmm5, %xmm2
	mulsd	 %xmm1, %xmm5

	addsd	 %xmm4, %xmm10
	movsd	 5 * SIZE(AO), %xmm4
	mulsd	 %xmm3, %xmm2

	addsd	 %xmm6, %xmm11
	movaps	 %xmm7, %xmm6
	mulsd	 %xmm1, %xmm7
	movsd	 2 * SIZE(BO), %xmm1

	addsd	 %xmm5, %xmm12
	movsd	 6 * SIZE(AO), %xmm5
	mulsd	 %xmm3, %xmm6
	movsd	 3 * SIZE(BO), %xmm3

	addsd	 %xmm2, %xmm13
	movaps	 %xmm0, %xmm2
	mulsd	 %xmm1, %xmm0

	addsd	 %xmm7, %xmm14
	movsd	 7 * SIZE(AO), %xmm7
	mulsd	 %xmm3, %xmm2

	addsd	 %xmm6, %xmm15
	movaps	 %xmm4, %xmm6
	mulsd	 %xmm1, %xmm4

	addsd	 %xmm0, %xmm8
	movsd	 8 * SIZE(AO), %xmm0
	mulsd	 %xmm3, %xmm6

	addsd	 %xmm2, %xmm9
	movaps	 %xmm5, %xmm2
	mulsd	 %xmm1, %xmm5

	addsd	 %xmm4, %xmm10
	movsd	 9 * SIZE(AO), %xmm4
	mulsd	 %xmm3, %xmm2

	addsd	 %xmm6, %xmm11
	movaps	 %xmm7, %xmm6
	mulsd	 %xmm1, %xmm7
	movsd	 4 * SIZE(BO), %xmm1

	addsd	 %xmm5, %xmm12
	movsd	10 * SIZE(AO), %xmm5
	mulsd	 %xmm3, %xmm6
	movsd	 5 * SIZE(BO), %xmm3

	addsd	 %xmm2, %xmm13
	PREFETCH (PREFETCHSIZE + 8) * SIZE(AO)
	movaps	 %xmm0, %xmm2
	mulsd	 %xmm1, %xmm0

	addsd	 %xmm7, %xmm14
	movsd	11 * SIZE(AO), %xmm7
	mulsd	 %xmm3, %xmm2

	addsd	 %xmm6, %xmm15
	movaps	 %xmm4, %xmm6
	mulsd	 %xmm1, %xmm4

	addsd	 %xmm0, %xmm8
	movsd	12 * SIZE(AO), %xmm0
	mulsd	 %xmm3, %xmm6

	addsd	 %xmm2, %xmm9
	movaps	 %xmm5, %xmm2
	mulsd	 %xmm1, %xmm5

	addsd	 %xmm4, %xmm10
	movsd	13 * SIZE(AO), %xmm4
	mulsd	 %xmm3, %xmm2

	addsd	 %xmm6, %xmm11
	movaps	 %xmm7, %xmm6
	mulsd	 %xmm1, %xmm7
	movsd	 6 * SIZE(BO), %xmm1

	addsd	 %xmm5, %xmm12
	movsd	14 * SIZE(AO), %xmm5
	mulsd	 %xmm3, %xmm6
	movsd	 7 * SIZE(BO), %xmm3

	addsd	 %xmm2, %xmm13
	movaps	 %xmm0, %xmm2
	mulsd	 %xmm1, %xmm0

	addsd	 %xmm7, %xmm14
	movsd	15 * SIZE(AO), %xmm7
	mulsd	 %xmm3, %xmm2
	subq   $-16 * SIZE, AO

	addsd	 %xmm6, %xmm15
	movaps	 %xmm4, %xmm6
	mulsd	 %xmm1, %xmm4

	addsd	 %xmm0, %xmm8
	movsd	 0 * SIZE(AO), %xmm0
	mulsd	 %xmm3, %xmm6

	addsd	 %xmm2, %xmm9
	movaps	 %xmm5, %xmm2
	mulsd	 %xmm1, %xmm5
	addq   $  8 * SIZE, BO

	addsd	 %xmm4, %xmm10
	movsd	 1 * SIZE(AO), %xmm4
	mulsd	 %xmm3, %xmm2
	decq   %rax

	addsd	 %xmm6, %xmm11
	movaps	 %xmm7, %xmm6
	mulsd	 %xmm1, %xmm7
	movsd	 0 * SIZE(BO), %xmm1

	addsd	 %xmm5, %xmm12
	movsd	 2 * SIZE(AO), %xmm5
	mulsd	 %xmm3, %xmm6
	movsd	 1 * SIZE(BO), %xmm3

	jne    .L12
	ALIGN_4

.L15:
	movq	K, %rax
	andq	$3, %rax
	BRANCH
	BRANCH
	je	.L19
	ALIGN_4

.L16:
	addsd	 %xmm2, %xmm13
	movaps	 %xmm0, %xmm2
	mulsd	 %xmm1, %xmm0

	addsd	 %xmm7, %xmm14
	movsd	 3 * SIZE(AO), %xmm7
	mulsd	 %xmm3, %xmm2

	addsd	 %xmm6, %xmm15
	movaps	 %xmm4, %xmm6
	mulsd	 %xmm1, %xmm4

	addsd	 %xmm0, %xmm8
	movsd	 4 * SIZE(AO), %xmm0
	mulsd	 %xmm3, %xmm6

	addsd	 %xmm2, %xmm9
	movaps	 %xmm5, %xmm2
	mulsd	 %xmm1, %xmm5

	addsd	 %xmm4, %xmm10
	movsd	 5 * SIZE(AO), %xmm4
	mulsd	 %xmm3, %xmm2

	addsd	 %xmm6, %xmm11
	movaps	 %xmm7, %xmm6
	mulsd	 %xmm1, %xmm7
	movsd	 2 * SIZE(BO), %xmm1

	addsd	 %xmm5, %xmm12
	movsd	 6 * SIZE(AO), %xmm5
	mulsd	 %xmm3, %xmm6
	movsd	 3 * SIZE(BO), %xmm3

	addq	$4 * SIZE, AO
	addq	$2 * SIZE, BO
	decq	%rax
	BRANCH
	jg	.L16
	ALIGN_4

.L19:
	movsd	ALPHA_R, %xmm4
	addsd	 %xmm2, %xmm13
	movsd	ALPHA_I, %xmm5
	addsd	 %xmm7, %xmm14
	addsd	 %xmm6, %xmm15

	movaps	 %xmm8,  %xmm0
	movaps	 %xmm10, %xmm1
	movaps	 %xmm12, %xmm2
	movaps	 %xmm14, %xmm3

	mulsd	%xmm4, %xmm8
	mulsd	%xmm5, %xmm0
	mulsd	%xmm4, %xmm10
	mulsd	%xmm5, %xmm1
	mulsd	%xmm4, %xmm12
	mulsd	%xmm5, %xmm2
	mulsd	%xmm4, %xmm14
	mulsd	%xmm5, %xmm3

	addsd	0 * SIZE(CO1), %xmm8
	addsd	1 * SIZE(CO1), %xmm0
	addsd	2 * SIZE(CO1), %xmm10
	addsd	3 * SIZE(CO1), %xmm1
	addsd	4 * SIZE(CO1), %xmm12
	addsd	5 * SIZE(CO1), %xmm2
	addsd	6 * SIZE(CO1), %xmm14
	addsd	7 * SIZE(CO1), %xmm3

	movsd	%xmm8,  0 * SIZE(CO1)
	movsd	%xmm0,  1 * SIZE(CO1)
	movsd	%xmm10, 2 * SIZE(CO1)
	movsd	%xmm1,  3 * SIZE(CO1)
	movsd	%xmm12, 4 * SIZE(CO1)
	movsd	%xmm2,  5 * SIZE(CO1)
	movsd	%xmm14, 6 * SIZE(CO1)
	movsd	%xmm3,  7 * SIZE(CO1)

	movaps	 %xmm9,  %xmm0
	movaps	 %xmm11, %xmm1
	movaps	 %xmm13, %xmm2
	movaps	 %xmm15, %xmm3

	mulsd	%xmm4, %xmm9
	mulsd	%xmm5, %xmm0
	mulsd	%xmm4, %xmm11
	mulsd	%xmm5, %xmm1
	mulsd	%xmm4, %xmm13
	mulsd	%xmm5, %xmm2
	mulsd	%xmm4, %xmm15
	mulsd	%xmm5, %xmm3

	addsd	0 * SIZE(CO2), %xmm9
	addsd	1 * SIZE(CO2), %xmm0
	addsd	2 * SIZE(CO2), %xmm11
	addsd	3 * SIZE(CO2), %xmm1
	addsd	4 * SIZE(CO2), %xmm13
	addsd	5 * SIZE(CO2), %xmm2
	addsd	6 * SIZE(CO2), %xmm15
	addsd	7 * SIZE(CO2), %xmm3

	movsd	%xmm9,  0 * SIZE(CO2)
	movsd	%xmm0,  1 * SIZE(CO2)
	movsd	%xmm11, 2 * SIZE(CO2)
	movsd	%xmm1,  3 * SIZE(CO2)
	movsd	%xmm13, 4 * SIZE(CO2)
	movsd	%xmm2,  5 * SIZE(CO2)
	movsd	%xmm15, 6 * SIZE(CO2)
	movsd	%xmm3,  7 * SIZE(CO2)

	addq	$8 * SIZE, CO1
	addq	$8 * SIZE, CO2

	decq	I			# i --
	jg	.L11
	ALIGN_4

.L20:
	testq	$2, M
	jle	.L30

	movq	B, BO

	movsd	 0 * SIZE(AO), %xmm0
	xorps	%xmm2,  %xmm2
	movsd	 1 * SIZE(AO), %xmm4
	xorps	%xmm5,  %xmm5
	movsd	 2 * SIZE(AO), %xmm5
	xorps	%xmm6,  %xmm6
	movsd	 3 * SIZE(AO), %xmm7

	movsd	 0 * SIZE(BO), %xmm1
	xorps	%xmm8,  %xmm8
	xorps	%xmm9,  %xmm9
	movsd	 1 * SIZE(BO), %xmm3
	xorps	%xmm10, %xmm10
	xorps	%xmm11, %xmm11

	movq	K, %rax
	sarq	$2, %rax
	je	.L25
	ALIGN_4

.L22:
	PREFETCH (PREFETCHSIZE + 0) * SIZE(AO)
	addsd	 %xmm2, %xmm9
	movaps	 %xmm0, %xmm2
	mulsd	 %xmm1, %xmm0

	addsd	 %xmm6, %xmm11
	movaps	 %xmm4, %xmm6
	mulsd	 %xmm1, %xmm4
	movsd	 2 * SIZE(BO), %xmm1

	addsd	 %xmm0, %xmm8
	movsd	 4 * SIZE(AO), %xmm0
	mulsd	 %xmm3, %xmm2

	addsd	 %xmm4, %xmm10
	movsd	 5 * SIZE(AO), %xmm4
	mulsd	 %xmm3, %xmm6
	movsd	 3 * SIZE(BO), %xmm3

	addsd	 %xmm2, %xmm9
	movaps	 %xmm5, %xmm2
	mulsd	 %xmm1, %xmm5

	addsd	 %xmm6, %xmm11
	movaps	 %xmm7, %xmm6
	mulsd	 %xmm1, %xmm7
	movsd	 4 * SIZE(BO), %xmm1

	addsd	 %xmm5, %xmm8
	movsd	 6 * SIZE(AO), %xmm5
	mulsd	 %xmm3, %xmm2

	addsd	 %xmm7, %xmm10
	movsd	 7 * SIZE(AO), %xmm7
	mulsd	 %xmm3, %xmm6
	movsd	 5 * SIZE(BO), %xmm3

	addsd	 %xmm2, %xmm9
	movaps	 %xmm0, %xmm2
	mulsd	 %xmm1, %xmm0

	addsd	 %xmm6, %xmm11
	movaps	 %xmm4, %xmm6
	mulsd	 %xmm1, %xmm4
	movsd	 6 * SIZE(BO), %xmm1

	addsd	 %xmm0, %xmm8
	movsd	 8 * SIZE(AO), %xmm0
	mulsd	 %xmm3, %xmm2

	addsd	 %xmm4, %xmm10
	movsd	 9 * SIZE(AO), %xmm4
	mulsd	 %xmm3, %xmm6
	movsd	 7 * SIZE(BO), %xmm3

	addsd	 %xmm2, %xmm9
	movaps	 %xmm5, %xmm2
	mulsd	 %xmm1, %xmm5

	addsd	 %xmm6, %xmm11
	movaps	 %xmm7, %xmm6
	mulsd	 %xmm1, %xmm7
	movsd	 8 * SIZE(BO), %xmm1

	addsd	 %xmm5, %xmm8
	movsd	10 * SIZE(AO), %xmm5
	mulsd	 %xmm3, %xmm2

	addsd	 %xmm7, %xmm10
	movsd	11 * SIZE(AO), %xmm7
	mulsd	 %xmm3, %xmm6
	movsd	 9 * SIZE(BO), %xmm3

	addq	$8 * SIZE, AO
	addq	$8 * SIZE, BO

	decq	%rax
	jne    .L22
	ALIGN_4

.L25:
	movq	K, %rax
	movsd	ALPHA_R, %xmm5
	movsd	ALPHA_I, %xmm7

	andq	$3, %rax
	BRANCH
	BRANCH
	je	.L29
	ALIGN_4

.L26:
	addsd	 %xmm2, %xmm9
	movaps	 %xmm0, %xmm2
	mulsd	 %xmm1, %xmm0

	addsd	 %xmm6, %xmm11
	movaps	 %xmm4, %xmm6
	mulsd	 %xmm1, %xmm4
	movsd	 2 * SIZE(BO), %xmm1

	mulsd	 %xmm3, %xmm2
	addsd	 %xmm0, %xmm8
	movsd	 2 * SIZE(AO), %xmm0

	mulsd	 %xmm3, %xmm6
	movsd	 3 * SIZE(BO), %xmm3
	addsd	 %xmm4, %xmm10
	movsd	 3 * SIZE(AO), %xmm4

	addq	$2 * SIZE, AO
	addq	$2 * SIZE, BO
	decq	%rax
	BRANCH
	jg	.L26
	ALIGN_4

.L29:
	addsd	 %xmm2, %xmm9
	addsd	 %xmm6, %xmm11

	movaps	 %xmm8,  %xmm12
	movaps	 %xmm10, %xmm13
	movaps	 %xmm9,  %xmm14
	movaps	 %xmm11, %xmm15

	mulsd	%xmm5, %xmm8
	mulsd	%xmm7, %xmm12
	mulsd	%xmm5, %xmm10
	mulsd	%xmm7, %xmm13
	mulsd	%xmm5, %xmm9
	mulsd	%xmm7, %xmm14
	mulsd	%xmm5, %xmm11
	mulsd	%xmm7, %xmm15

	addsd	0 * SIZE(CO1), %xmm8
	addsd	1 * SIZE(CO1), %xmm12
	addsd	2 * SIZE(CO1), %xmm10
	addsd	3 * SIZE(CO1), %xmm13

	addsd	0 * SIZE(CO2), %xmm9
	addsd	1 * SIZE(CO2), %xmm14
	addsd	2 * SIZE(CO2), %xmm11
	addsd	3 * SIZE(CO2), %xmm15

	movsd	%xmm8,  0 * SIZE(CO1)
	movsd	%xmm12, 1 * SIZE(CO1)
	movsd	%xmm10, 2 * SIZE(CO1)
	movsd	%xmm13, 3 * SIZE(CO1)

	movsd	%xmm9,  0 * SIZE(CO2)
	movsd	%xmm14, 1 * SIZE(CO2)
	movsd	%xmm11, 2 * SIZE(CO2)
	movsd	%xmm15, 3 * SIZE(CO2)

	addq	$4 * SIZE, CO1
	addq	$4 * SIZE, CO2
	ALIGN_4

.L30:
	testq	$1, M
	je	.L39
	ALIGN_4

	movq	B, BO

	movsd	 0 * SIZE(AO), %xmm0
	xorps	%xmm7,  %xmm7
	movsd	 1 * SIZE(AO), %xmm2
	xorps	%xmm5,  %xmm5

	movsd	 0 * SIZE(BO), %xmm1
	xorps	%xmm8,  %xmm8
	xorps	%xmm9,  %xmm9
	movsd	 1 * SIZE(BO), %xmm3

	movq	K, %rax
	sarq	$2, %rax
	je	.L35
	ALIGN_4

.L32:
	addsd	 %xmm5, %xmm8
	movsd	 2 * SIZE(BO), %xmm5
	mulsd	 %xmm0, %xmm1
	PREFETCH (PREFETCHSIZE + 0) * SIZE(AO)

	addsd	 %xmm7, %xmm9
	movsd	 3 * SIZE(BO), %xmm7
	mulsd	 %xmm0, %xmm3
	movsd	 2 * SIZE(AO), %xmm0

	addsd	 %xmm1, %xmm8
	movsd	 4 * SIZE(BO), %xmm1
	mulsd	 %xmm2, %xmm5

	addsd	 %xmm3, %xmm9
	movsd	 5 * SIZE(BO), %xmm3
	mulsd	 %xmm2, %xmm7
	movsd	 3 * SIZE(AO), %xmm2

	addsd	 %xmm5, %xmm8
	movsd	 6 * SIZE(BO), %xmm5
	mulsd	 %xmm0, %xmm1

	addsd	 %xmm7, %xmm9
	movsd	 7 * SIZE(BO), %xmm7
	mulsd	 %xmm0, %xmm3
	movsd	 4 * SIZE(AO), %xmm0

	addsd	 %xmm1, %xmm8
	movsd	 8 * SIZE(BO), %xmm1
	mulsd	 %xmm2, %xmm5

	addsd	 %xmm3, %xmm9
	movsd	 9 * SIZE(BO), %xmm3
	mulsd	 %xmm2, %xmm7
	movsd	 5 * SIZE(AO), %xmm2

	addq	$4 * SIZE, AO
	addq	$8 * SIZE, BO

	decq	%rax
	jne    .L32
	ALIGN_4

.L35:
	movq	K, %rax

	addsd	 %xmm5, %xmm8
	addsd	 %xmm7, %xmm9

	movsd	ALPHA_R, %xmm6
	movsd	ALPHA_I, %xmm7

	andq	$3, %rax
	BRANCH
	BRANCH
	je	.L38
	ALIGN_4

.L36:
	mulsd	 %xmm0, %xmm1
	addq	$2 * SIZE, BO
	mulsd	 %xmm0, %xmm3
	movsd	 1 * SIZE(AO), %xmm0

	addsd	 %xmm1, %xmm8
	movsd	 0 * SIZE(BO), %xmm1
	addsd	 %xmm3, %xmm9
	movsd	 1 * SIZE(BO), %xmm3

	addq	$1 * SIZE, AO
	decq	%rax
	BRANCH
	jg	.L36
	ALIGN_4

.L38:
	movaps	%xmm8, %xmm10
	movaps	%xmm9, %xmm11

	mulsd	%xmm6, %xmm8
	mulsd	%xmm7, %xmm10
	mulsd	%xmm6, %xmm9
	mulsd	%xmm7, %xmm11

	addsd	0 * SIZE(CO1), %xmm8
	addsd	1 * SIZE(CO1), %xmm10
	addsd	0 * SIZE(CO2), %xmm9
	addsd	1 * SIZE(CO2), %xmm11

	movsd	%xmm8,   0 * SIZE(CO1)
	movsd	%xmm10,  1 * SIZE(CO1)
	movsd	%xmm9,   0 * SIZE(CO2)
	movsd	%xmm11,  1 * SIZE(CO2)
	ALIGN_4
	
.L39:
	movq	BO, B
	decq	J			# j --
	jg	.L10
	ALIGN_4

.L40:
	testq	$1, N
	je	.L999

	movq	C, CO1
	addq	LDC, C

	movq	A, AO

	movq	M,  I
	sarq	$2, I
	jle	.L50
	ALIGN_4

.L41:
	movq	B, BO

	movsd	 0 * SIZE(AO), %xmm0
	xorps	%xmm9,   %xmm9
	movsd	 1 * SIZE(AO), %xmm1
	xorps	%xmm11,  %xmm11
	movsd	 2 * SIZE(AO), %xmm2
	xorps	%xmm13,  %xmm13
	movsd	 3 * SIZE(AO), %xmm3
	xorps	%xmm15,  %xmm15

	movsd	 0 * SIZE(BO), %xmm4
	xorps	%xmm8,  %xmm8
	movsd	 1 * SIZE(BO), %xmm5
	xorps	%xmm10, %xmm10
	prefetcht0     7 * SIZE(CO1)
	xorps	%xmm12, %xmm12
	xorps	%xmm14, %xmm14

	movq	K, %rax
	sarq	$2, %rax
	je	.L45
	ALIGN_4

.L42:
	addsd	 %xmm9,  %xmm8
	movsd	 4 * SIZE(AO), %xmm9
	mulsd	 %xmm4, %xmm0
	PREFETCH (PREFETCHSIZE + 0) * SIZE(AO)

	addsd	 %xmm11, %xmm10
	movsd	 5 * SIZE(AO), %xmm11
	mulsd	 %xmm4, %xmm1

	addsd	 %xmm13, %xmm12
	movsd	 6 * SIZE(AO), %xmm13
	mulsd	 %xmm4, %xmm2

	addsd	 %xmm15, %xmm14
	movsd	 7 * SIZE(AO), %xmm15
	mulsd	 %xmm4, %xmm3
	movsd	 2 * SIZE(BO), %xmm4

	addsd	 %xmm0, %xmm8
	movsd	 8 * SIZE(AO), %xmm0
	mulsd	 %xmm5, %xmm9

	addsd	 %xmm1, %xmm10
	movsd	 9 * SIZE(AO), %xmm1
	mulsd	 %xmm5, %xmm11

	addsd	 %xmm2, %xmm12
	movsd	10 * SIZE(AO), %xmm2
	mulsd	 %xmm5, %xmm13

	addsd	 %xmm3, %xmm14
	movsd	11 * SIZE(AO), %xmm3
	mulsd	 %xmm5, %xmm15
	movsd	 3 * SIZE(BO), %xmm5

	addsd	 %xmm9,  %xmm8
	movsd	12 * SIZE(AO), %xmm9
	mulsd	 %xmm4, %xmm0
	PREFETCH (PREFETCHSIZE + 8) * SIZE(AO)

	addsd	 %xmm11, %xmm10
	movsd	13 * SIZE(AO), %xmm11
	mulsd	 %xmm4, %xmm1

	addsd	 %xmm13, %xmm12
	movsd	14 * SIZE(AO), %xmm13
	mulsd	 %xmm4, %xmm2

	addsd	 %xmm15, %xmm14
	movsd	15 * SIZE(AO), %xmm15
	mulsd	 %xmm4, %xmm3
	movsd	 4 * SIZE(BO), %xmm4
	subq	$-16 * SIZE, AO

	addsd	 %xmm0, %xmm8
	movsd	 0 * SIZE(AO), %xmm0
	mulsd	 %xmm5, %xmm9

	addsd	 %xmm1, %xmm10
	movsd	 1 * SIZE(AO), %xmm1
	mulsd	 %xmm5, %xmm11
	addq	$  4 * SIZE, BO

	addsd	 %xmm2, %xmm12
	movsd	 2 * SIZE(AO), %xmm2
	mulsd	 %xmm5, %xmm13
	decq	%rax

	addsd	 %xmm3, %xmm14
	movsd	 3 * SIZE(AO), %xmm3
	mulsd	 %xmm5, %xmm15
	movsd	 1 * SIZE(BO), %xmm5

	jne    .L42
	ALIGN_4

.L45:
	movq	K, %rax

	movsd	ALPHA_R, %xmm6
	movsd	ALPHA_I, %xmm7

	addsd	 %xmm9,  %xmm8
	addsd	 %xmm11, %xmm10
	addsd	 %xmm13, %xmm12
	addsd	 %xmm15, %xmm14

	andq	$3, %rax
	BRANCH
	BRANCH
	je	.L49
	ALIGN_4

.L46:
	mulsd	 %xmm4, %xmm0
	mulsd	 %xmm4, %xmm1
	mulsd	 %xmm4, %xmm2
	mulsd	 %xmm4, %xmm3
	movsd	 1 * SIZE(BO), %xmm4

	addsd	 %xmm0, %xmm8
	movsd	 4 * SIZE(AO), %xmm0
	addsd	 %xmm1, %xmm10
	movsd	 5 * SIZE(AO), %xmm1
	addsd	 %xmm2, %xmm12
	movsd	 6 * SIZE(AO), %xmm2
	addsd	 %xmm3, %xmm14
	movsd	 7 * SIZE(AO), %xmm3

	addq	$4 * SIZE, AO
	addq	$1 * SIZE, BO
	decq	%rax
	BRANCH
	jg	.L46
	ALIGN_4

.L49:
	movaps	%xmm8,  %xmm9
	movaps	%xmm10, %xmm11
	movaps	%xmm12, %xmm13
	movaps	%xmm14, %xmm15

	mulsd	%xmm6, %xmm8
	mulsd	%xmm7, %xmm9
	mulsd	%xmm6, %xmm10
	mulsd	%xmm7, %xmm11
	mulsd	%xmm6, %xmm12
	mulsd	%xmm7, %xmm13
	mulsd	%xmm6, %xmm14
	mulsd	%xmm7, %xmm15

	addsd	0 * SIZE(CO1), %xmm8
	addsd	1 * SIZE(CO1), %xmm9
	addsd	2 * SIZE(CO1), %xmm10
	addsd	3 * SIZE(CO1), %xmm11
	addsd	4 * SIZE(CO1), %xmm12
	addsd	5 * SIZE(CO1), %xmm13
	addsd	6 * SIZE(CO1), %xmm14
	addsd	7 * SIZE(CO1), %xmm15

	movsd	%xmm8,  0 * SIZE(CO1)
	movsd	%xmm9,  1 * SIZE(CO1)
	movsd	%xmm10, 2 * SIZE(CO1)
	movsd	%xmm11, 3 * SIZE(CO1)
	movsd	%xmm12, 4 * SIZE(CO1)
	movsd	%xmm13, 5 * SIZE(CO1)
	movsd	%xmm14, 6 * SIZE(CO1)
	movsd	%xmm15, 7 * SIZE(CO1)

	addq	$8 * SIZE, CO1

	decq	I			# i --
	jg	.L41
	ALIGN_4

.L50:
	testq	$2, M
	jle	.L60

	movq	B, BO

	movsd	 0 * SIZE(AO), %xmm0
	xorps	%xmm2,   %xmm2
	movsd	 1 * SIZE(AO), %xmm1
	xorps	%xmm3,   %xmm3

	movsd	 0 * SIZE(BO), %xmm4
	xorps	%xmm8,  %xmm8
	movsd	 1 * SIZE(BO), %xmm5
	xorps	%xmm10, %xmm10

	movq	K, %rax
	sarq	$2, %rax
	je	.L55
	ALIGN_4

.L52:
	addsd	 %xmm2, %xmm8
	movsd	 2 * SIZE(AO), %xmm2
	mulsd	 %xmm4, %xmm0
	PREFETCH (PREFETCHSIZE + 0) * SIZE(AO)

	addsd	 %xmm3, %xmm10
	movsd	 3 * SIZE(AO), %xmm3
	mulsd	 %xmm4, %xmm1
	movsd	 2 * SIZE(BO), %xmm4

	addsd	 %xmm0, %xmm8
	movsd	 4 * SIZE(AO), %xmm0
	mulsd	 %xmm5, %xmm2
	addq	$8 * SIZE, AO

	addsd	 %xmm1, %xmm10
	movsd	-3 * SIZE(AO), %xmm1
	mulsd	 %xmm5, %xmm3
	movsd	 3 * SIZE(BO), %xmm5

	addsd	 %xmm2, %xmm8
	movsd	-2 * SIZE(AO), %xmm2
	mulsd	 %xmm4, %xmm0
	addq	$4 * SIZE, BO

	addsd	 %xmm3, %xmm10
	movsd	-1 * SIZE(AO), %xmm3
	mulsd	 %xmm4, %xmm1
	movsd	 0 * SIZE(BO), %xmm4

	addsd	 %xmm0, %xmm8
	movsd	 0 * SIZE(AO), %xmm0
	mulsd	 %xmm5, %xmm2
	decq	%rax

	addsd	 %xmm1, %xmm10
	movsd	 1 * SIZE(AO), %xmm1
	mulsd	 %xmm5, %xmm3
	movsd	 1 * SIZE(BO), %xmm5

	jne    .L52
	ALIGN_4

.L55:
	movq	K, %rax
	movsd	ALPHA_R, %xmm6
	movsd	ALPHA_I, %xmm7

	addsd	 %xmm2, %xmm8
	addsd	 %xmm3, %xmm10

	andq	$3, %rax
	BRANCH
	BRANCH
	je	.L59
	ALIGN_4

.L56:
	mulsd	 %xmm4, %xmm0
	mulsd	 %xmm4, %xmm1
	movsd	 1 * SIZE(BO), %xmm4

	addsd	 %xmm0, %xmm8
	movsd	 2 * SIZE(AO), %xmm0
	addsd	 %xmm1, %xmm10
	movsd	 3 * SIZE(AO), %xmm1

	addq	$2 * SIZE, AO
	addq	$1 * SIZE, BO
	decq	%rax
	BRANCH
	jg	.L56
	ALIGN_4

.L59:
	movaps	%xmm8,  %xmm9
	movaps	%xmm10, %xmm11

	mulsd	%xmm6, %xmm8
	mulsd	%xmm7, %xmm9
	mulsd	%xmm6, %xmm10
	mulsd	%xmm7, %xmm11

	addsd	0 * SIZE(CO1), %xmm8
	addsd	1 * SIZE(CO1), %xmm9
	addsd	2 * SIZE(CO1), %xmm10
	addsd	3 * SIZE(CO1), %xmm11

	movsd	%xmm8,  0 * SIZE(CO1)
	movsd	%xmm9,  1 * SIZE(CO1)
	movsd	%xmm10, 2 * SIZE(CO1)
	movsd	%xmm11, 3 * SIZE(CO1)

	addq	$4 * SIZE, CO1
	ALIGN_4

.L60:
	testq	$1, M
	je	.L999
	ALIGN_4

	movq	B, BO

	movsd	 0 * SIZE(AO), %xmm0
	xorps	%xmm5,  %xmm5
	movsd	 1 * SIZE(AO), %xmm2
	xorps	%xmm7,  %xmm7

	movsd	 0 * SIZE(BO), %xmm1
	xorps	%xmm8,  %xmm8
	movsd	 1 * SIZE(BO), %xmm3
	xorps	%xmm9,  %xmm9
	movsd	 2 * SIZE(AO), %xmm4
	movsd	 3 * SIZE(AO), %xmm6

	movq	K, %rax
	sarq	$2, %rax
	je	.L65
	ALIGN_4

.L62:
	addsd	 %xmm5, %xmm8
	movsd	 2 * SIZE(BO), %xmm5
	mulsd	 %xmm0, %xmm1
	movsd	 4 * SIZE(AO), %xmm0

	addsd	 %xmm7, %xmm9
	movsd	 3 * SIZE(BO), %xmm7
	mulsd	 %xmm2, %xmm3
	movsd	 5 * SIZE(AO), %xmm2

	addsd	 %xmm1, %xmm8
	movsd	 4 * SIZE(BO), %xmm1
	mulsd	 %xmm4, %xmm5
	movsd	 6 * SIZE(AO), %xmm4

	addsd	 %xmm3, %xmm9
	movsd	 5 * SIZE(BO), %xmm3
	mulsd	 %xmm6, %xmm7
	movsd	 7 * SIZE(AO), %xmm6

	addq	$4 * SIZE, AO
	addq	$4 * SIZE, BO

	decq	%rax
	jne    .L62

	addsd	 %xmm5, %xmm8
	addsd	 %xmm7, %xmm9
	ALIGN_4

.L65:
	movq	K, %rax
	movsd	ALPHA_R, %xmm6
	movsd	ALPHA_I, %xmm7

	andq	$3, %rax
	BRANCH
	BRANCH
	je	.L68
	ALIGN_4

.L66:
	movsd	 0 * SIZE(AO), %xmm0
	movsd	 0 * SIZE(BO), %xmm1

	mulsd	 %xmm0, %xmm1
	addsd	 %xmm1, %xmm8

	addq	$1 * SIZE, AO
	addq	$1 * SIZE, BO

	decq	%rax
	BRANCH
	jg	.L66
	ALIGN_4

.L68:
	addsd	%xmm9, %xmm8

	movaps	%xmm8, %xmm9
	mulsd	%xmm6, %xmm8
	mulsd	%xmm7, %xmm9

	addsd	0 * SIZE(CO1), %xmm8
	addsd	1 * SIZE(CO1), %xmm9

	movsd	%xmm8,  0 * SIZE(CO1)
	movsd	%xmm9,  1 * SIZE(CO1)
	ALIGN_4
	
.L999:
	movq	  0(%rsp), %rbx
	movq	  8(%rsp), %rbp
	movq	 16(%rsp), %r12
	movq	 24(%rsp), %r13
	movq	 32(%rsp), %r14
	movq	 40(%rsp), %r15

#ifdef WINDOWS_ABI
	movq	 48(%rsp), %rdi
	movq	 56(%rsp), %rsi
	movups	 64(%rsp), %xmm6
	movups	 80(%rsp), %xmm7
	movups	 96(%rsp), %xmm8
	movups	112(%rsp), %xmm9
	movups	128(%rsp), %xmm10
	movups	144(%rsp), %xmm11
	movups	160(%rsp), %xmm12
	movups	176(%rsp), %xmm13
	movups	192(%rsp), %xmm14
	movups	208(%rsp), %xmm15
#endif

	addq	$STACKSIZE, %rsp
	ret

	EPILOGUE
