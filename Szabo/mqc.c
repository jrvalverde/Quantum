/*
 *  Minimal basis STO-3G calculation on HeH+
 *
 *  C translation of FORTRAN code
 *
 *  2001(C) José R. Valverde <jrvalverde@es.embnet.org>
 *  
 */

#include <stdio.h>
#include <math.h>

#ifdef LONG_DOUBLE
#  define PI	3.1415926535897932384626433832795029L
#else
#  define PI  3.14159265358979323846
#endif

struct integrals {
    double s12,     	/* overlap */
    	   t11,     	/* kinetic energy */
	   t12,
	   t22,
	   v11a,    	/* potential energy */
	   v12a,
	   v22a,
	   v11b,
	   v12b,
	   v22b,
	   v1111,
	   v2111,
	   v2121,
	   v2211,
	   v2221,
	   v2222;
} intg;

struct matrix {
    double s[2][2];
    double x[2][2];
    double xt[2][2];
    double h[2][2];
    double f[2][2];
    double g[2][2];
    double c[2][2];
    double fprime[2][2];
    double cprime[2][2];
    double p[2][2];
    double oldp[2][2];
    double tt[2][2][2][2];
    double e[2][2];
} m;

/* forward declarations */
void computeHF(int iop, int n, double r, double zeta1, double zeta2, 
    	       double za, double zb);
void calc_integrals(int iop, int n, double r, double zeta1, double zeta2, 
    	            double za, double zb);
double f0(double arg);
#ifdef NEED_ERF
    #define erf(x)  dblerf(x)
#endif
double dblerf(double arg);
double s(double a, double b, double rab2);
double t(double a, double b, double rab2);
double v(double a, double b, double rab2, double rcp2, double zc);
double two_e(double a, double b, double c, double d, double rab2, 
    	     double rcd2, double rpq2);
void collect_integrals(int iop, int n, double r, double zeta1,
    double zeta2, double za, double zb);
void scf(int iop, int n, double r, double zeta1, double zeta2, 
    	 double za, double zb);
void formg();
void matdiag(double f[2][2], double c[2][2], double e[2][2]);
void matmult(double a[2][2], double b[2][2], double c[2][2], int im, int m);
void matout(double a[2][2], int im, int in, int m, int n, char *label);




/* This is a little dummy main program which calls computeHF() */
main()
{
    int iop,	    	    	    /* Verbose IO level */ 
        n;  	    	    	    /* Number of Gaussian functions to use */
    double r, zeta1, zeta2, za, zb;
    
    iop = 2;
    /* Number of primitive gaussians to use in calculation (N in STO-NG) */
    n = 3;
    /* bond length */
    r = 1.4632;
    /* exponents of the 1s Slater functions */
    zeta1 = 2.0925;
    zeta2 = 1.24;
    /* atomic numbers of the two nuclei */
    za = 2.0;
    zb = 1.0;

    /* Given that
     *	    g_1s(alpha) = ((2 * alpha / PI)^(3/4)) * e^(-alpha * r * r)
     * or
     *                                          2
     *                          3/4     -alpha r
     *	    g   = (2 alpha / PI)      e
     *	     1s
     *
     * is a normalized primitive 1s Gaussian, then the program can use
     * for basis functions any one of the following three least-squares
     * fits to Slater type functions:
     *
     *	   CGF
     *  Phi    (zeta = 1.0, STO-1G) = g  (0.270950)
     *     1s                         1s
     *
     *     CGF
     *  Phi    (zeta = 1.0, STO-2G) = 0.678914 g  (0.151623) +
     *     1s                                   1s
     *
     *	    	    	    	      0.430129 g  (0.851819)
     *                                          1s
     *
     *    CGF
     * Phi    (zeta = 1.0, STO-3G) = 0.444635 g  (0.109818) +
     *    1s                                   1s
     *
     *                               0.535328 g  (0.405771) +
     *                                         1s
     *
     *                               0.154329 g  (2.22766)
     *                                         1s
     */
     
    computeHF(iop, n, r, zeta1, zeta2, za, zb);
}


/*
 *  computeHF(iop, n, r, zeta1, zeta2, za, zb)
 *
 *  Do a Hartee-Fock calculation for a two-electron diatomic
 *  using the 1s minimal STO-NG basis set
 *
 *  	iop = 0     No printing whatsoever (to optimize exponents, say)
 *  	iop = 1     Print only converged results
 *  	iop = 2     Print every iteration
 *  	n   	    STO-NG calculation (n=1, 2 or 3)
 *  	r   	    Bond length (AU)
 *  	zeta1	    Slater orbital exponent (function 1)
 *  	zeta2	    Slater orbital exponent (function 2)
 *  	za  	    Atomic number (atom A)
 *  	zb  	    Atomic number (Atom B)
 */

void computeHF(iop, n, r, zeta1, zeta2, za, zb)
int iop, n;
double r, zeta1, zeta2, za, zb;
{
    if (iop != 0)
    	printf("   STO-%dG FOR ATOMIC NUMBERS %5.2g AND %5.2g\n\n", n, za, zb);
    
    /* calculate all the one and two-electron integrals */
    calc_integrals(iop, n, r, zeta1, zeta2, za, zb);
    
    /* be inefficient and put all integrals in pretty arrays */
    collect_integrals(iop, n, r, zeta1, zeta2, za, zb);
    
    /* perform the SCF calculation */
    scf(iop, n, r, zeta1, zeta2, za, zb);
}


/*
 *  calc_integrals(iop, n, r, zeta1, zeta2, za, zb)
 *
 *  calculates all the basic integrals needed for SCF calculation
 */
 
void calc_integrals(iop, n, r, zeta1, zeta2, za, zb)
int iop, n;
double r, zeta1, zeta2, za, zb;
{
    extern struct integrals intg;
    
    /* These are the contraction coefficients and exponents for
     * a normalized 1s Slater orbital with exponent 1.0 in terms
     * of normalized 1s primitive gaussians
     *                                          
     *                          3/4     -alpha r²
     *	    g   = (2 alpha / PI)      e
     *	     1s
     *
     *	   CGF                           n
     *  Phi    (zeta = 1.0, STO-NG) = SUM   coeff * g  (expon)
     *     1s                            1           1s
     *
     *
     *	Phi (zeta, STO-NG) ==> alpha = expon * zeta²
     *	    	    	       D = coeff *  (2 alpha/pi)^3/4
     *	    	    	       g_1s = D * e^(-alpha r²)
     *
     *
     */
    double coeff[3][3] = {/* STO-1G  STO-2G    STO-3G */
    	    	    	    1.0,    0.678914, 0.444635,
	    	    	    0.0,    0.430129, 0.535328,
	    	    	    0.0,    0.0,      0.154329 };
			    
    double expon[3][3] = {/*  STO-1G  	  STO-2G     STO-3G */
    	    	    	    0.270950,	0.151623,   0.109818,
    	    	    	    0.0,    	0.851819,   0.405771,
			    0.0,    	0.0,	    2.22766 };

    double d1[3], d2[3];    /* normalized contraction coefficients */
    double a1[3], a2[3];    /* scaled exponents */
    double r2;	    	    /* squared radius */
    double rap, rap2;	    /* distance A-P (and squared dist.) */
    double rbp, rbp2;	    /* distance B-P (and squared dist.) */
    double raq, raq2;
    double rbq, rbq2;
    double rpq, rpq2;
    int i, j, k, l;
    
    r2 = r * r;
    /*
     * Scale the exponents (A) of primitive gaussians
     * Include normalization in contraction coefficients (d)
     */
    for (i = 0; i < n; i++) {
    	/* must use n-1 to account for C's zero offset arrays */
    	a1[i] = expon[i][n-1] * (zeta1 * zeta1);
 	d1[i] = coeff[i][n-1] * pow((2.0 * a1[i] / PI), 0.75);
	
	a2[i] = expon[i][n-1] * (zeta2 * zeta2);
	d2[i] = coeff[i][n-1] * pow((2.0 * a2[i] /PI), 0.75);
    }
    /*
     * D and A are now the contraction coefficients and exponents
     * in terms of unnormalized primitive gaussians
     */
    /* initialize calculations */
    intg.s12 = 0.0;
    intg.t11 = intg.t12 = intg.t22 = 0.0;
    intg.v11a = intg.v12a = intg.v22a = 0.0;
    intg.v11b = intg.v12b = intg.v22b = 0.0;
    intg.v1111 = intg.v2111 = intg.v2121 = intg.v2211 = intg.v2221 = intg.v2222 = 0.0;
    /*
     * Calculate one-electron integral
     * Center A is first atom, center B is second atom
     * Origin is on center A
     *	V12A = off-diagonal nuclear attraction to center A, etc.
     */
    for (i = 0; i < n; i++)
    	for (j = 0; j < n; j++) {
	    /* RAP2 = squared distance between center A and center P, etc. */
	    rap = a2[j] * r / (a1[i] + a2[j]);
	    rap2 = rap * rap;
	    rbp = r - rap;
	    rbp2 = rbp * rbp;
	    
	    /* Overlap integrals */
	    intg.s12 += s(a1[i], a2[j], r2)  * d1[i] * d2[j];
	    
	    /* Kinetic energy */
	    intg.t11 += t(a1[i], a1[j], 0.0) * d1[i] * d1[j];
	    intg.t12 += t(a1[i], a2[j], r2)  * d1[i] * d2[j];
	    intg.t22 += t(a2[i], a2[j], 0.0) * d2[i] * d2[j];
	    
	    /* nuclear attraction */
	    intg.v11a += v(a1[i], a1[j], 0.0, 0.0,  za) * d1[i] * d1[j];
	    intg.v12a += v(a1[i], a2[j], r2,  rap2, za) * d1[i] * d2[j];
	    intg.v22a += v(a2[i], a2[j], 0.0, r2,   za) * d2[i] * d2[j];
	    
	    intg.v11b += v(a1[i], a1[j], 0.0, r2,   zb) * d1[i] * d1[j];
	    intg.v12b += v(a1[i], a2[j], r2,  rbp2, zb) * d1[i] * d2[j];
	    intg.v22b += v(a2[i], a2[j], 0.0, 0.0,  zb) * d2[i] * d2[j];
	}
    /*
     * Calculate two electron integrals
     */
    for (i = 0; i < n; i++)
      for (j = 0; j < n; j++)
	for (k = 0; k < n; k++)
	  for (l = 0; l < n; l++) {
	    /* compute distances */
	    rap = a2[i] * r / (a2[i] + a1[j]);
	    rbp = r - rap;
	    raq = a2[k] * r / (a2[k] + a1[l]);
	    rbq = r - raq;
	    rpq = rap - raq;
	    rap2 = rap * rap;
	    rbp2 = rbp * rbp;
	    raq2 = raq * raq;
	    rbq2 = rbq * rbq;
	    rpq2 = rpq * rpq;
	    
	    /* compute integrals */
	    intg.v1111 += two_e(a1[i], a1[j], a1[k], a1[l], 0.0, 0.0, 0.0)
	    	    	* d1[i] * d1[j] * d1[k] * d1[l];
	    intg.v2111 += two_e(a2[i], a1[j], a1[k], a1[l], r2,  0.0, rap2)
	    	    	* d2[i] * d1[j] * d1[k] * d1[l];
	    intg.v2121 += two_e(a2[i], a1[j], a2[k], a1[l], r2,  r2,  rpq2)
	    	    	* d2[i] * d1[j] * d2[k] * d1[l];
	    intg.v2211 += two_e(a2[i], a2[j], a1[k], a1[l], 0.0, 0.0, r2)
	    	    	* d2[i] * d2[j] * d1[k] * d1[l];
	    intg.v2221 += two_e(a2[i], a2[j], a2[k], a1[l], 0.0, r2,  rbq2)
	    	    	* d2[i] * d2[j] * d2[k] * d1[l];
	    intg.v2222 += two_e(a2[i], a2[j], a2[k], a2[l], 0.0, 0.0, 0.0)
	    	    	* d2[i] * d2[j] * d2[k] * d2[l];
    }
    /* Done
     * Print out values if verbose requested
     */
    if (iop != 0) {
    	printf("   R          ZETA1      ZETA2      S12        T11\n\n");
    	printf("%11.6f%11.6f%11.6f%11.6f%11.6f\n\n", r, zeta1, zeta2, intg.s12, intg.t11);
	printf("   T12        T22        V11A       V12A       V22A\n\n");
	printf("%11.6f%11.6f%11.6f%11.6f%11.6f\n\n", intg.t12, intg.t22, intg.v11a, intg.v12a, intg.v22a);
	printf("   V11B       V12B       V22B       V1111      V2111\n\n");
	printf("%11.6f%11.6f%11.6f%11.6f%11.6f\n\n", intg.v11b, intg.v12b, intg.v22b, intg.v1111, intg.v2111);
	printf("   V2121      V2211      V2221      V2222\n\n");
    	printf("%11.6f%11.6f%11.6f%11.6f\n\n", intg.v2121, intg.v2211, intg.v2221, intg.v2222);
    }
}


/*
 *  function f0(arg)
 *
 *  Calculates the F function
 *  F0 only (S-type orbitals)
 */

double f0(double arg)
{
    double result;
    if (arg >= 1.0e-6)
    	/* f0 in terms of the error function */
	result = sqrt(PI / arg) * erf(sqrt(arg)) / 2.0;
    else
    	/* asymptotic value for small arguments */
    	result = 1.0 - arg / 3.0;
    return result;
}


/*
 * function erf(arg)
 *
 *  calculates the error function according to a rational
 * approximation from M. Abramowitz and I. A. Stegun,
 * Handbook of Mathematical functions, Dover.
 * Absolute error is less than 1.5 * 10^-7
 *
 *  Some machines have a builtin function computing erf as
 *  the error function of x defined as
 *                                                  -t²
 *  	erf(x) = (2/sqrt(pi)) integral{0 to x} of (e   ) dt
 *
 *  We state to use this one by defining NEED_ERF
 *  We prefer the builtin since it gives closer results to the reference
 *  	listing in the book (note that this one gives the same results as 
 *  	the one in the reference FORTRAN code).
 */
double dblerf(double arg)
{
    double p = 0.3275911;
    double a[5] = { 0.25829592, -0.284496736, 1.421413741,
		   -1.453152027, 1.061405439 };
    double t, tn, poly, result;
    int i;
    
    t = 1.0 / (1.0 + p * arg);
    tn = t;
    poly = a[0] * tn;
    for (i = 1; i < 5; i++) {
    	tn *= t;
	poly += a[i] * tn;
    }
    result = (1.0 - poly * exp(-arg * arg));
    return result;
}


/*
 *  function T(a, b, rab2)
 *
 *  calculate overlaps for un-normalized primitives
 */
double s(double a, double b, double rab2)
{
    return ( pow(PI / (a + b), 1.5) * exp(-a * b * rab2 / (a + b)) );
}


/*
 *  function T(a, b, rab2)
 *
 *  calculate kinetic energy integrals for un-normalized primitives
 */
double t(double a, double b, double rab2)
{
    return ( a * b / (a + b) * (3.0 - 2.0 * a * b * rab2 / (a + b))
    	    * pow(PI/(a+b), 1.5) * exp(-a * b * rab2 / (a + b)) );
}


/*
 *  function V(a, b, rab2, rcp2, zc)
 *
 *  calculates un-normalized nuclear attraction integrals
 */
double v(double a, double b, double rab2, double rcp2, double zc)
{
    double result;
    
    result = 2.0 * PI / (a + b) * f0((a+b) * rcp2) * 
    	     exp(-a * b * rab2 / (a + b));
    result = -result * zc;
    return result;
}


/*
 *  function two_e(a, b, c, d, rab2, rcd2, rpq2)
 *
 *  calculate two-electron integrals for un-normalized primitives
 *  a, b, c, d are the exponents alpha, beta, etc.
 *  rab2 equals squared distance between center a and centerb, etc.
 */
double two_e(a, b, c, d, rab2, rcd2, rpq2)
double a, b, c, d, rab2, rcd2, rpq2;
{
    return (2.0 * pow(PI, 2.5) / ((a+b) * (c+d) * sqrt(a+b+c+d)) *
    	    f0((a+b) * (c+d) * rpq2 / (a+b+c+d)) *
	    exp(-a * b * rab2 / (a+b) - c * d * rcd2 / (c+d)) );
}


/*
 *  collect_integrals(iop, n, r, zeta1, zeta2, za, zb)
 *
 *  This takes the basic integrals from common storage and assembles
 *  the relevant matrices, that is, S, H, X, XT and two-electron
 *  integrals
 */
void collect_integrals(int iop, int n, double r, double zeta1,
    double zeta2, double za, double zb)
{
    extern struct matrix m;
    extern struct integrals intg;
    int i, j, k, l;

    /*
     *	Form core Hamiltonian
     */
    m.h[0][0] = intg.t11 + intg.v11a + intg.v11b;
    m.h[0][1] = intg.t12 + intg.v12a + intg.v12b;
    m.h[1][0] = m.h[0][1];
    m.h[1][1] = intg.t22 + intg.v22a + intg.v22b;
    /*
     * Form overlap matrix
     */
    m.s[0][0] = 1.0;
    m.s[0][1] = intg.s12;
    m.s[1][0] = m.s[0][1];
    m.s[1][1] = 1.0;
    /*
     * use canonical orthogonalization
     */
    m.x[0][0] = 1.0 / sqrt(2.0 * (1.0 + intg.s12));
    m.x[1][0] = m.x[0][0];
    m.x[0][1] = 1.0 / sqrt(2.0 * (1.0 - intg.s12));
    m.x[1][1] = -m.x[0][1];
    /*
     * Transpose of transformation matrix
     */
    m.xt[0][0] = m.x[0][0];
    m.xt[0][1] = m.x[1][0];
    m.xt[1][0] = m.x[0][1];
    m.xt[1][1] = m.x[1][1];
    /*
     * matrix of two electron integrals
     */
    m.tt[0][0][0][0] = intg.v1111;
    m.tt[1][0][0][0] = intg.v2111;
    m.tt[0][1][0][0] = intg.v2111;
    m.tt[0][0][1][0] = intg.v2111;
    m.tt[0][0][0][1] = intg.v2111;
    m.tt[1][0][1][0] = intg.v2121;
    m.tt[0][1][1][0] = intg.v2121;
    m.tt[1][0][0][1] = intg.v2121;
    m.tt[0][1][0][1] = intg.v2121;
    m.tt[1][1][0][0] = intg.v2211;
    m.tt[0][0][1][1] = intg.v2211;
    m.tt[1][1][1][0] = intg.v2221;
    m.tt[1][1][0][1] = intg.v2221;
    m.tt[1][0][1][1] = intg.v2221;
    m.tt[0][1][1][1] = intg.v2221;
    m.tt[1][1][1][1] = intg.v2222;
    /*
     * Done. Print out matrices if so requested
     */
    if (iop != 0) {
    	matout(m.s, 2, 2, 2, 2, "S   ");
	matout(m.x, 2, 2, 2, 2, "X   ");
	matout(m.h, 2, 2, 2, 2, "H   ");
	printf("\n\n");
	for (i = 0; i < 2; i++)
	  for (j = 0; j < 2; j++)
	    for (k = 0; k < 2; k++)
	      for (l = 0; l < 2; l++)
	      	printf("   (%2d%2d%2d%2d )%10.6f\n", i, j, k, l, m.tt[i][j][k][l]);
    }
}


/*
 *  SCF(IOP, N, R, ZETA1, ZETA2, ZA, ZB)
 *
 *  Perform the SCF iterations
 */
void scf(int iop, int n, double r, double zeta1, double zeta2, 
    	 double za, double zb)
{
    extern struct matrix m;
    double crit = 1.0e-4;   	/* convergence criterion for density matrix */
    int maxit = 25; 	    	/* maximum number of iterations */
    int iter, i, j, k;
    double en;	    	    	/* electronic energy */
    double ent;     	    	/* total energy */
    double delta;
    
    iter = 0;
    /*
     * Use core Hamiltonian for initial guess at F, i.e. (P=0)
     */
    for (i = 0; i < 2; i++)
    	for (j = 0; j < 2; j++)
	    m.p[i][j] = 0.0;
    /*
     * Iteration loop
     */
    do {
    	iter++;
	if (iop >= 2)
	    printf("\n    START OF ITERATION NUMBER = %2d\n", iter);
	/*
	 * form two-electron part of Fock matrix from P
	 */
	formg();
	if (iop >= 2)
	    matout(m.g, 2, 2, 2, 2, "G   ");
	/*
	 * add core hamiltonian to get fock matrix
	 */
	for (i = 0; i < 2; i++)
	    for (j = 0; j < 2; j++)
	    	m.f[i][j] = m.h[i][j] + m.g[i][j];
	/*
	 * calculate electronic energy
	 */
	en = 0.0;
	for (i = 0; i < 2; i++)
	    for (j = 0; j < 2; j++)
	    	en += 0.5 * m.p[i][j] * (m.h[i][j] + m.f[i][j]);
	if (iop >= 2) {
	    matout(m.f, 2, 2, 2, 2, "F   ");
	    printf("\n\n\n    ELECTRONIC ENERGY = %20.12f\n", en);
	}
	/*
	 * transform Fock matrix using G for temporary storage
	 */
	matmult(m.f, m.x, m.g, 2, 2);
	matmult(m.xt, m.g, m.fprime, 2, 2);
	/*
	 * diagonalize transformed Fock matrix
	 */
	matdiag(m.fprime, m.cprime, m.e);
	/*
	 * transform eigenvectors to get matrix C
	 */
	matmult(m.x, m.cprime, m.c, 2, 2);
	/*
	 * form new density matrix
	 */
	for (i = 0; i < 2; i++)
	    for (j = 0; j < 2; j++) {
	    	/* save present density matrix
		 * before creating new one
		 */
		m.oldp[i][j] = m.p[i][j];
		m.p[i][j] = 0.0;
		for (k = 0; k < 1; k++)
		    m.p[i][j] += 2.0 * m.c[i][k] * m.c[j][k];
	    }
	if (iop >= 2) {
	    matout(m.fprime, 2, 2, 2, 2, "F'  ");
	    matout(m.cprime, 2, 2, 2, 2, "C'  ");
	    matout(m.e, 2, 2, 2, 2, "E   ");
	    matout(m.c, 2, 2, 2, 2, "C   ");
	    matout(m.p, 2, 2, 2, 2, "P   ");
	}
	/*
	 * Calculate delta
	 */
	delta = 0.0;
	for (i = 0; i < 2; i++)
	    for (j = 0; j < 2; j++)
	    	delta += (m.p[i][j] - m.oldp[i][j]) * (m.p[i][j] - m.oldp[i][j]);
	delta = sqrt(delta/4);
	if (iop >= 2)
	    printf("\n    DELTA(CONVERGENCE OF DENSITY MATRIX) = %10.6f\n", delta);
	/*
	 * check for convergence
	 */
    } while ((delta > crit) && (iter <= maxit));
 
    if (iter > maxit) {
    	/* Something wrong here */
	printf("    NO CONVERGENCE IN SCF\n");
    	return;
    
    }
    /*
     * calculation converged if it got here
     * add nuclear repulsion to get total energy
     */
    ent = en + za * zb / r;
    if (iop != 0) {
    	printf("\n\n    CALCULATION CONVERGED\n\n"); 
	printf("    ELECTRONIC ENERGY = %20.12f\n\n", en);
	printf("    TOTAL ENERGY =      %20.12f\n\n", ent);
    }
    if (iop == 1) {
    	/* print out the final results if
	 * have not done so already */
	matout(m.g, 2, 2, 2, 2, "G   ");
	matout(m.f, 2, 2, 2, 2, "F   ");
	matout(m.e, 2, 2, 2, 2, "E   ");
	matout(m.p, 2, 2, 2, 2, "P   ");
    }
    /* P·S matrix has Mulliken populations */
    matmult(m.p, m.s, m.oldp, 2, 2);
    if (iop != 0)
    	matout(m.oldp, 2, 2, 2, 2, "PS  ");
}


/*
 *  FORMG()
 *
 *  calculate the G matrix from the density matrix
 *  and two-electron integrals
 */
void formg()
{
    extern struct matrix m;
    int i, j, k, l;
    
    for (i = 0; i < 2; i++)
    	for (j = 0; j < 2; j++) {
	    m.g[i][j] = 0.0;
	    for (k = 0; k < 2; k++)
	      for (l = 0; l < 2; l++)
	        m.g[i][j] += m.p[k][l] * (m.tt[i][j][k][l] - 0.5 * m.tt[i][l][k][j]);
	}
}


/*
 *  DIAG(F, C, E)
 *
 *  Diagonalizes F to give eigenvectors in C and eigenvalues in E
 *  Theta is the angle describing solution
 */
void matdiag(double f[2][2], double c[2][2], double e[2][2])
{
    double temp;
    double theta;
    
    if (fabs(f[0][0] - f[1][1]) <= 1.0e-20)
    	/* here is symmetry determined solution (homonuclear diatomic) */
	theta = PI / 4.0;
    else
    	/* solution for heteronuclear diatomic */
	theta = 0.5 * atan(2.0 * f[0][1] / (f[0][0] - f[1][1]));
    
    c[0][0] = cos(theta);
    c[1][0] = sin(theta);
    c[0][1] = sin(theta);
    c[1][1] = -cos(theta);
    
    e[0][0] = (f[0][0] * cos(theta) * cos(theta)) +
    	      (f[1][1] * sin(theta) * sin(theta)) +
	      (f[0][1] * sin(2.0 * theta));
    e[1][1] = (f[1][1] * cos(theta) * cos(theta)) +
    	      (f[0][0] * sin(theta) * sin(theta)) -
	      (f[0][1] * sin(2.0 * theta));
    e[1][0] = 0.0;
    e[0][1] = 0.0;
    
    /* order eigenvalues and eigenvectors */
    if (e[1][1] <= e[0][0]) {
    	temp = e[1][1];
	e[1][1] = e[0][0];
	e[0][0] = temp;
	temp = c[0][1];
	c[0][1] = c[0][0];
	c[0][0] = temp;
	temp = c[1][1];
	c[1][1] = c[1][0];
	c[1][0] = temp;
    }
}


/*
 * MATMULT(A, B, C, IM, M)
 *
 *  Multiplies two square matrices A and B to get C
 */
void matmult(double a[2][2], double b[2][2], double c[2][2], int im, int m)
{
    /* We assume IM and M will ALWAYS be 2
     * This works for this problem. Won't for others: will need a better
     * solution, which will be awkward in C.
     */
    int i, j, k;
    for (i = 0; i < 2; i++)
    	for (j = 0; j < 2; j++) {
	    c[i][j] = 0.0;
	    for (k = 0; k < 2; k++)
	    	c[i][j] += a[i][k] * b[k][j];
	}
}


/*
 *  MATOUT(A, IM, IN, M, N, LABEL)
 *
 *  Print matrices of size M by N
 */
void matout(double a[2][2], int im, int in, int m, int n, char *label)
{
    /* WE ASSUME WE ARE ALWAYS CALLED WITH 2x2 MATRICES 
     * which is the case in this program. Others will need a better solution */
    int i;
    
    printf("\n\n\n\n    THE %s ARRAY\n", label);
    printf("                           1                  2\n");
    for (i = 0; i < m; i++)
	printf("%10d      %18.10f %18.10f\n", i, a[i][0], a[i][1]);
}
