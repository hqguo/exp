! This set of modules is useful for verification tests and development of
! turbulence models.

MODULE TURBULENCE

USE PRECISION_PARAMETERS
USE GLOBAL_CONSTANTS
USE MESH_POINTERS
USE MESH_VARIABLES
USE COMP_FUNCTIONS

IMPLICIT NONE

PRIVATE
PUBLIC :: ANALYTICAL_SOLUTION, sandia_dat, init_spectral_data, spectral_output
 
CONTAINS


SUBROUTINE SANDIA_DAT(NM)
IMPLICIT NONE

! This routine reads the file 'iso_ini.dat', which is generated by turb_init.
! This exe generates a random velocity field with a spectrum that matches the
! Comte-Bellot/Corrsin 1971 experimental data.

REAL :: XXX
INTEGER :: I,J,K,II,JJ,KK,FILE_NUM
INTEGER, INTENT(IN) :: NM

CALL POINT_TO_MESH(NM)

IF (IBAR/=32 .AND. IBAR/=64) THEN
   WRITE(LU_ERR,'(A)') 'Error 1 in SANDIA_DAT!'
   STOP
ENDIF  

FILE_NUM = GET_FILE_NUMBER()
IF (IBAR==32) OPEN (UNIT=FILE_NUM,FILE='iso_ini.32.rjm.dat',FORM='formatted',STATUS='old')
IF (IBAR==64) OPEN (UNIT=FILE_NUM,FILE='iso_ini.64.rjm.dat',FORM='formatted',STATUS='old') 
     
READ (FILE_NUM,*) II, JJ, KK	! reads number of points in each direction

IF (II/=IBAR .OR. JJ/=JBAR .OR. KK/=KBAR) THEN
   WRITE(LU_ERR,'(A)') 'Error 2 in SANDIA_DAT!'
   STOP
ENDIF

READ (FILE_NUM,*) XXX, XXX, XXX	! reads lower physical dimension limit
READ (FILE_NUM,*) XXX, XXX, XXX	! reads upper physical dimension limit

DO K = 1,KBAR
   DO J = 1,JBAR
      DO I = 1,IBAR

         READ (FILE_NUM,*) U(I,J,K), V(I,J,K), W(I,J,K), XXX, XXX
         
         U(I,J,K) = 0.01*U(I,J,K)	! scale from cm/s
         V(I,J,K) = 0.01*V(I,J,K)
         W(I,J,K) = 0.01*W(I,J,K)
         
      ENDDO
   ENDDO
ENDDO

CLOSE (UNIT=FILE_NUM)

! subtract mean
U(1:IBAR,1:JBAR,1:KBAR) = U(1:IBAR,1:JBAR,1:KBAR) - SUM(U(1:IBAR,1:JBAR,1:KBAR))/REAL(IBAR*JBAR*KBAR,EB)
V(1:IBAR,1:JBAR,1:KBAR) = V(1:IBAR,1:JBAR,1:KBAR) - SUM(V(1:IBAR,1:JBAR,1:KBAR))/REAL(IBAR*JBAR*KBAR,EB)
W(1:IBAR,1:JBAR,1:KBAR) = W(1:IBAR,1:JBAR,1:KBAR) - SUM(W(1:IBAR,1:JBAR,1:KBAR))/REAL(IBAR*JBAR*KBAR,EB)

! apply periodic b.c.
U(0,:,:) = U(IBAR,:,:)
V(:,0,:) = V(:,JBAR,:)
W(:,:,0) = W(:,:,KBAR)

END SUBROUTINE SANDIA_DAT


SUBROUTINE init_spectral_data(NM)
USE MEMORY_FUNCTIONS, ONLY: ChkMemErr
IMPLICIT NONE
INTEGER, INTENT(IN) :: NM
INTEGER :: IZERO
INTEGER, POINTER :: n
TYPE (MESH_TYPE), POINTER :: M

CALL POINT_TO_MESH(NM)
M => MESHES(NM)
n => M%IBAR

! real work arrays
ALLOCATE(M%PWORK1(n,n,n),STAT=IZERO)
CALL ChkMemErr('init_spectral_data','PWORK1',IZERO)
M%PWORK1 = 0._EB
ALLOCATE(M%PWORK2(n,n,n),STAT=IZERO)
CALL ChkMemErr('init_spectral_data','PWORK2',IZERO)
M%PWORK2 = 0._EB
ALLOCATE(M%PWORK3(n,n,n),STAT=IZERO)
CALL ChkMemErr('init_spectral_data','PWORK3',IZERO)
M%PWORK3 = 0._EB
ALLOCATE(M%PWORK4(n,n,n),STAT=IZERO)
CALL ChkMemErr('init_spectral_data','PWORK4',IZERO)
M%PWORK4 = 0._EB

! complex work arrays
ALLOCATE(M%PWORK5(n,n,n),STAT=IZERO)
CALL ChkMemErr('init_spectral_data','PWORK5',IZERO)
M%PWORK5 = 0._EB
ALLOCATE(M%PWORK6(n,n,n),STAT=IZERO)
CALL ChkMemErr('init_spectral_data','PWORK6',IZERO)
M%PWORK6 = 0._EB
ALLOCATE(M%PWORK7(n,n,n),STAT=IZERO)
CALL ChkMemErr('init_spectral_data','PWORK7',IZERO)
M%PWORK7 = 0._EB
ALLOCATE(M%PWORK8(n,n,n),STAT=IZERO)
CALL ChkMemErr('init_spectral_data','PWORK8',IZERO)
M%PWORK8 = 0._EB

END SUBROUTINE init_spectral_data


SUBROUTINE spectral_output(TT,NM)
IMPLICIT NONE
INTEGER, INTENT(IN) :: NM
REAL(EB), INTENT(IN) :: TT
INTEGER :: nn(3)
REAL(EB),     POINTER, DIMENSION(:,:,:) :: UU,VV,WW,HH
COMPLEX(DPC), POINTER, DIMENSION(:,:,:) :: UUHT,VVHT,WWHT,KKHT

call POINT_TO_MESH(NM)
nn = IBAR
UU => PWORK1
VV => PWORK2
WW => PWORK3
HH => PWORK4
UUHT => PWORK5
VVHT => PWORK6
WWHT => PWORK7
KKHT => PWORK8

UU = U(1:nn(1),1:nn(2),1:nn(3))
VV = V(1:nn(1),1:nn(2),1:nn(3))
WW = W(1:nn(1),1:nn(2),1:nn(3))
HH = H(1:nn(1),1:nn(2),1:nn(3))

! take fourier transform of velocities in 3d...
call fft3d_f90(UU, UUHT, nn)
call fft3d_f90(VV, VVHT, nn)
call fft3d_f90(WW, WWHT, nn)

! calc the spectral kinetic energy
call complex_tke_f90(KKHT, UUHT, VVHT, WWHT, nn(1))

! total up the spectral energy for each mode and integrate over
! the resolved modes...
call spectrum_f90(KKHT, nn(1), XF-XS, nint(100._EB*TT))
      
IF (TURB_INIT) call sandia_out(UU,VV,WW,HH,nn(1))
                      
spec_clock = spec_clock + dt_spec

END SUBROUTINE spectral_output


SUBROUTINE sandia_out(u,v,w,p,n)
IMPLICIT NONE

! Variable declarations

INTEGER, INTENT(IN) :: n
REAL(EB), INTENT(IN) :: u(n,n,n)
REAL(EB), INTENT(IN) :: v(n,n,n)
REAL(EB), INTENT(IN) :: w(n,n,n)
REAL(EB), INTENT(IN) :: p(n,n,n)
REAL(EB) :: uu,vv,ww,pp,ke

INTEGER :: i,j,k,file_num

! This subroutine writes out the velocity, relative pressure, and
! turbulent kinetic energy to the file 'ini_salsa.dat'.  This is
! then used as input to the 'turb_init' program.

file_num = GET_FILE_NUMBER()
OPEN (unit=file_num, file='ini_salsa.dat', form='formatted', status='unknown', position='rewind')

WRITE (file_num,997) n,n,n
WRITE (file_num,998) 0,0,0
WRITE (file_num,998) 2*pi,2*pi,2*pi

DO k = 1,n
   DO j = 1,n
      DO i = 1,n

         pp = 10._EB*p(i,j,k)  ! convert to dynes from pascals
         uu = 100._EB*u(i,j,k) ! convert to cm/s from m/s
         vv = 100._EB*v(i,j,k)
         ww = 100._EB*w(i,j,k)
         	
         ke = 0.5_EB*( uu**2 + vv**2 + ww**2 )

         WRITE (file_num,999) uu,vv,ww,pp,ke
         
      END DO
   END DO
END DO

CLOSE (unit=file_num)


997	FORMAT(3(i6,8x))
998	FORMAT(3(f12.6,2x))
999	FORMAT(5(f12.6,2x))


END SUBROUTINE sandia_out


SUBROUTINE complex_tke_f90(tkeht, upht, vpht, wpht, n)
IMPLICIT NONE
INTEGER, INTENT(IN) :: n
COMPLEX(DPC), INTENT(OUT) :: tkeht(n,n,n)
COMPLEX(DPC), INTENT(IN) :: upht(n,n,n),vpht(n,n,n),wpht(n,n,n)
INTEGER i,j,k

do k = 1,n
   do j = 1,n
      do i = 1,n
         tkeht(i,j,k) = 0.5_EB*( upht(i,j,k)*conjg(upht(i,j,k)) + &
                                 vpht(i,j,k)*conjg(vpht(i,j,k)) + &
                                 wpht(i,j,k)*conjg(wpht(i,j,k)) )
      end do
   end do
end do

END SUBROUTINE complex_tke_f90


SUBROUTINE fft3d_f90(v, vht, nn)
IMPLICIT NONE
INTEGER, INTENT(IN) :: nn(3)
REAL(EB), INTENT(IN) :: v(nn(1),nn(2),nn(3))
COMPLEX(DPC), INTENT(INOUT) :: vht(nn(1),nn(2),nn(3))

! This routine performs an FFT on the real array v and places the
! result in the complex array vht.

INTEGER :: i,j,k
REAL(EB) :: z2(2*nn(1))
!REAL(EB) :: tke

! convert v to spectral space

!tke = 0._EB

do k = 1,nn(3)
   do j = 1,nn(2)
      do i = 1,nn(1)      
         vht(i,j,k) = cmplx(v(i,j,k),0.0_EB,kind=DPC)
         !tke = tke + 0.5_EB*v(i,j,k)**2
      end do
   end do
end do

!tke = tke/real(nn(1)*nn(2)*nn(3),EB)

!print*, ' fft3d internal check-'
!print*, ' tkeave (physical) =', tke

!do k=1,nn(3)
!   do j=1,nn(2)
!      do i=1,nn(1)
!         vht(i,j,k) = cmplx(float(i)+k*100,float(j)+.5+k*100)
!      enddo
!   enddo
!enddo

call fourt_f90(vht,nn,3,-1,0,z2)
!call four3(vht,-1)

do k = 1,nn(3)
   do j = 1,nn(2)
      do i = 1,nn(1)
         vht(i,j,k) = vht(i,j,k)/nn(1)/nn(2)/nn(3)
      end do
   end do
end do

!tke = 0._EB
!do k = 1,nn(3)
!   do j = 1,nn(2)
!      do i = 1,nn(1)
!         tke = tke + 0.5_EB*real(vht(i,j,k)*conjg(vht(i,j,k)),kind=EB)
!      end do
!   end do
!end do

!print*, ' tkeave (spectral) =', tke

END SUBROUTINE fft3d_f90


SUBROUTINE spectrum_f90(vht, n, Lm, iFVfilenum)
IMPLICIT NONE
INTEGER, INTENT(IN) :: n, iFVfilenum 
COMPLEX(DPC), INTENT(IN) :: vht(n,n,n)
REAL(EB), INTENT(IN) :: Lm

! This routine is copied from SNL and is intended to compute the
! kinetic energy spectrum in wavenumber space.

INTEGER :: kmax, kx, ky, kz, k, ksum, file_num
INTEGER :: num(0:n)

REAL(EB) :: rk, temp, vsum, rkx, rky, rkz, etot
REAL(EB) :: vt(0:n)

CHARACTER*6 :: ext
CHARACTER*18 :: filename

! for dimensional wavenumbers
REAL(EB) :: wn(0:n)
REAL(EB) :: L, k0
      
L = Lm

k0 = 2*PI/L
kmax = n/2
	
wn(0) = 0._EB
do k = 1,n
   wn(k) = k0*k
end do

do k = 0,n
   vt(k) = 0._EB
   num(k) = 0
end do

etot = 0._EB

do kx = 1,n

   rkx = real(kx-1,kind=EB)
   if (rkx .gt. kmax) then
      rkx = n - rkx
   end if

   do ky = 1,n

      rky = real(ky-1,kind=EB)
      if (rky .gt. kmax) then
         rky = n - rky
      end if

      do kz = 1,n

         rkz = real(kz-1,kind=EB)
         if (rkz .gt. kmax) then
            rkz = n - rkz
         end if

         rk     = sqrt(rkx*rkx + rky*rky + rkz*rkz)
         k      = nint(rk)

         num(k) = num(k) + 1
         temp   = real(vht(kx,ky,kz)*conjg(vht(kx,ky,kz)),kind=EB)
         etot   = etot + sqrt(temp)
         vt(k)  = vt(k) + sqrt(temp)*(L/(2*PI))

      end do
   end do
end do

write(6,*) ' '
write(6,*) ' Spectrum Internal Check-'
write(6,*) ' Total Energy (-) in 3D field = ', etot
write(6,*) ' k(-), Num(k), k(1/cm), E(cm3/s2) '
ksum = 0
vsum = 0._EB
do k = 0,n
   write(6,*) k, num(k), wn(k), vt(k)
   ksum = ksum + num(k)
   vsum = vsum + vt(k)
end do

write(6,*) ' ksum: ', ksum
write(6,*) ' Total Energy (-) in spectrum: ', vsum
write(6,*) ' '

! write the spectral data to a file
! units are (1/cm) for wavenumber and (cm3/s2) for energy
! this matches the Comte-Bellot/Corrsin units

write(ext,1) iFVfilenum
filename = 'spec' // TRIM(ext) // '.dat'

file_num = GET_FILE_NUMBER()
open (unit=file_num, file=filename, status='unknown', form='formatted')

do k = 0,n
   write (file_num,*) wn(k), vt(k)
end do

close (unit = file_num)

1	format (i3.3)

END SUBROUTINE spectrum_f90


SUBROUTINE fourt_f90(data3,nn,ndim,isign,iform,work)
IMPLICIT NONE
! Converted to F90 10/8/2008 by RJM
!
!     the cooley-tukey fast fourier transform in usasi basic fortran
!     transform(j1,j2,,,,) = sum(data(i1,i2,,,,)*w1**((i2-1)*(j2-1))
!                                 *w2**((i2-1)*(j2-1))*,,,),
!     where i1 and j1 run from 1 to nn(1) and w1=exp(isign*2*pi=
!     sqrt(-1)/nn(1)), etc.  there is no limit on the dimensionality
!     (number of subscripts) of the data array.  if an inverse
!     transform (isign=+1) is performed upon an array of transformed
!     (isign=-1) data, the original data will reappear.
!     multiplied by nn(1)*nn(2)*,,,  the array of input data must be
!     in complex format.  however, if all imaginary parts are zero (i.e.
!     the data are disguised real) running time is cut up to forty per-
!     cent.  (for fastest transform of real data, nn(1) should be even.)
!     the transform values are always complex and are returned in the
!     original array of data, replacing the input data.  the length
!     of each dimension of the data array may be any integer.  the
!     program runs faster on composite integers than on primes, and is
!     particularly fast on numbers rich in factors of two.
!
!     timing is in fact given by the following formula.  let ntot be the
!     total number of points (real or complex) in the data array, that
!     is, ntot=nn(1)*nn(2)*...  decompose ntot into its prime factors,
!     such as 2**k2 * 3**k3 * 5**k5 * ...  let sum2 be the sum of all
!     the factors of two in ntot, that is, sum2 = 2*k2.  let sumf be
!     the sum of all other factors of ntot, that is, sumf = 3*k3*5*k5*..
!     the time taken by a multidimensional transform on these ntot data
!     is t = t0 + ntot*(t1+t2*sum2+t3*sumf).  on the cdc 3300 (floating
!     point add time = six microseconds), t = 3000 + ntot*(600+40*sum2+
!     175*sumf) microseconds on complex data.
!
!     implementation of the definition by summation will run in a time
!     proportional to ntot*(nn(1)+nn(2)+...).  for highly composite ntot
!     the savings offered by this program can be dramatic.  a one-dimen-
!     sional array 4000 in length will be transformed in 4000*(600+
!     40*(2+2+2+2+2)+175*(5+5+5)) = 14.5 seconds versus about 4000*
!     4000*175 = 2800 seconds for the straightforward technique.
!
!     the fast fourier transform places three restrictions upon the
!     data.
!     1.  the number of input data and the number of transform values
!     must be the same.
!     2.  both the input data and the transform values must represent
!     equispaced points in their respective domains of time and
!     frequency.  calling these spacings deltat and deltaf, it must be
!     true that deltaf=2*pi/(nn(i)*deltat).  of course, deltat need not
!     be the same for every dimension.
!     3.  conceptually at least, the input data and the transform output
!     represent single cycles of periodic functions.
!
!     the calling sequence is--
!     call fourt(data,nn,ndim,isign,iform,work)
!
!     data is the array used to hold the real and imaginary parts
!     of the data on input and the transform values on output.  it
!     is a multidimensional floating point array, with the real and
!     imaginary parts of a datum stored immediately adjacent in storage
!     (such as fortran iv places them).  normal fortran ordering is
!     expected, the first subscript changing fastest.  the dimensions
!     are given in the integer array nn, of length ndim.  isign is -1
!     to indicate a forward transform (exponential sign is -) and +1
!     for an inverse transform (sign is +).  iform is +1 if the data are
!     complex, 0 if the data are real.  if it is 0, the imaginary
!     parts of the data must be set to zero.  as explained above, the
!     transform values are always complex and are stored in array data.
!     work is an array used for working storage.  it is floating point
!     real, one dimensional of length equal to twice the largest array
!     dimension nn(i) that is not a power of two.  if all nn(i) are
!     powers of two, it is not needed and may be replaced by zero in the
!     calling sequence.  thus, for a one-dimensional array, nn(1) odd,
!     work occupies as many storage locations as data.  if supplied,
!     work must not be the same array as data.  all subscripts of all
!     arrays begin at one.
!
!     example 1.  three-dimensional forward fourier transform of a
!     complex array dimensioned 32 by 25 by 13 in fortran iv.
!     dimension data(32,25,13),work(50),nn(3)
!     complex data
!     data nn/32,25,13/
!     do 1 i=1,32
!     do 1 j=1,25
!     do 1 k=1,13
!  1  data(i,j,k)=complex value
!     call fourt(data,nn,3,-1,1,work)
!
!     example 2.  one-dimensional forward transform of a real array of
!     length 64 in fortran ii,
!     dimension data(2,64)
!     do 2 i=1,64
!     data(1,i)=real part
!  2  data(2,i)=0.
!     call fourt(data,64,1,-1,0,0)
!
!     there are no error messages or error halts in this program.  the
!     program returns immediately if ndim or any nn(i) is less than one.
!
!     program by norman brenner from the basic program by charles
!     rader,  june 1967.  the idea for the digit reversal was
!     suggested by ralph alter.
!
!     this is the fastest and most versatile version of the fft known
!     to the author.  a program called four2 is available that also
!     performs the fast fourier transform and is written in usasi basic
!     fortran.  it is about one third as long and restricts the
!     dimensions of the input array (which must be complex) to be powers
!     of two.  another program, called four1, is one tenth as long and
!     runs two thirds as fast on a one-dimensional complex array whose
!     length is a power of two.
!
!     reference--
!     ieee audio transactions (june 1967), special issue on the fft.

      INTEGER, INTENT(IN) :: nn(3),ndim,isign,iform
      COMPLEX(DPC), INTENT(INOUT) :: data3(nn(1),nn(2),nn(3))
      REAL(EB), INTENT (INOUT) :: work(2*nn(1))
      
      INTEGER :: ifact(32),ntot,idim,np1,n,np2,m,ntwo,iif,idiv,iquot,irem,inon2,     &
                 icase,ifmin,i1rng,i,j,k,np2hf,i2,i1max,i1,i3,j3,nwork,ifp2,ifp1,    &
                 i2max,np1tw,ipar,k1,k2,mmax,lmax,l,kmin,kdif,kstep,k3,k4,np1hf,     &
                 j1min,j1,j2min,j2max,j2,j2rng,j1max,j3max,jmin,jmax,iconj,nhalf,    &
                 imin,imax,nprev=0,np0=0

      REAL(EB) :: data(2*nn(1)*nn(2)*nn(3)),tempr,tempi,u1r,u1i,u2r,u2i,u3r,         &
                  u3i,u4r,u4i,t2r,t2i,t3r,t3i,t4r,t4i,sumr,sumi,oldsr,oldsi,         &
                  difr,difi,theta,wr,wi,w2r,w2i,w3r,w3i,wstpr,wstpi,twowr
      
      REAL(EB), PARAMETER :: twopi=6.2831853071796, rthlf=0.70710678118655
      
      ! reshape data3 to 1D array
      data=0._EB
      n=1
      do k=1,nn(3)
        do j=1,nn(2)
          do i=1,nn(1)
            data(n)=real(data3(i,j,k),EB)
            data(n+1)=aimag(data3(i,j,k))
            n=n+2
          enddo
        enddo
      enddo
      
      if(ndim-1)920,1,1
1     ntot=2
      do 2 idim=1,ndim
      if(nn(idim))920,920,2
2     ntot=ntot*nn(idim)
!
!     main loop for each dimension
!
      np1=2
      do 910 idim=1,ndim
      n=nn(idim)
      np2=np1*n
      if(n-1)920,900,5
!
!     is n a power of two and if not, what are its factors
!
5     m=n
      ntwo=np1
      iif=1
      idiv=2
10    iquot=m/idiv
      irem=m-idiv*iquot
      if(iquot-idiv)50,11,11
11    if(irem)20,12,20
12    ntwo=ntwo+ntwo
      ifact(iif)=idiv
      iif=iif+1
      m=iquot
      go to 10
20    idiv=3
      inon2=iif
30    iquot=m/idiv
      irem=m-idiv*iquot
      if(iquot-idiv)60,31,31
31    if(irem)40,32,40
32    ifact(iif)=idiv
      iif=iif+1
      m=iquot
      go to 30
40    idiv=idiv+2
      go to 30
50    inon2=iif
      if(irem)60,51,60
51    ntwo=ntwo+ntwo
      go to 70
60    ifact(iif)=m
!
!     separate four cases--
!        1. complex transform or real transform for the 4th, 9th,etc.
!           dimensions.
!        2. real transform for the 2nd or 3rd dimension.  method--
!           transform half the data, supplying the other half by con-
!           jugate symmetry.
!        3. real transform for the 1st dimension, n odd.  method--
!           set the imaginary parts to zero.
!        4. real transform for the 1st dimension, n even.  method--
!           transform a complex array of length n/2 whose real parts
!           are the even numbered real values and whose imaginary parts
!           are the odd numbered real values.  separate and supply
!           the second half by conjugate symmetry.
!
70    icase=1
      ifmin=1
      i1rng=np1
      if(idim-4)71,100,100
71    if(iform)72,72,100
72    icase=2
      i1rng=np0*(1+nprev/2)
      if(idim-1)73,73,100
73    icase=3
      i1rng=np1
      if(ntwo-np1)100,100,74
74    icase=4
      ifmin=2
      ntwo=ntwo/2
      n=n/2
      np2=np2/2
      ntot=ntot/2
      i=1
      do 80 j=1,ntot
      data(j)=data(i)
80    i=i+2
!
!     shuffle data by bit reversal, since n=2**k.  as the shuffling
!     can be done by simple interchange, no working array is needed
!
100   if(ntwo-np2)200,110,110
110   np2hf=np2/2
      j=1
      do 150 i2=1,np2,np1
      if(j-i2)120,130,130
120   i1max=i2+np1-2
      do 125 i1=i2,i1max,2
      do 125 i3=i1,ntot,np2
      j3=j+i3-i2
      tempr=data(i3)
      tempi=data(i3+1)
      data(i3)=data(j3)
      data(i3+1)=data(j3+1)
      data(j3)=tempr
125   data(j3+1)=tempi
130   m=np2hf
140   if(j-m)150,150,145
145   j=j-m
      m=m/2
      if(m-np1)150,140,140
150   j=j+m
      go to 300
!
!     shuffle data by digit reversal for general n
!
200   nwork=2*n
      do 270 i1=1,np1,2
      do 270 i3=i1,ntot,np2
      j=i3
      do 260 i=1,nwork,2
      if(icase-3)210,220,210
210   work(i)=data(j)
      work(i+1)=data(j+1)
      go to 230
220   work(i)=data(j)
      work(i+1)=0._EB
230   ifp2=np2
      iif=ifmin
240   ifp1=ifp2/ifact(iif)
      j=j+ifp1
      if(j-i3-ifp2)260,250,250
250   j=j-ifp2
      ifp2=ifp1
      iif=iif+1
      if(ifp2-np1)260,260,240
260   continue
      i2max=i3+np2-np1
      i=1
      do 270 i2=i3,i2max,np1
      data(i2)=work(i)
      data(i2+1)=work(i+1)
270   i=i+2
!
!     main loop for factors of two.  perform fourier transforms of
!     length four, with one of length two if needed.  the twiddle factor
!     w=exp(isign*2*pi*sqrt(-1)*m/(4*mmax)).  check for w=isign*sqrt(-1)
!     and repeat for w=w*(1+isign*sqrt(-1))/sqrt(2).
!
300   if(ntwo-np1)600,600,305
305   np1tw=np1+np1
      ipar=ntwo/np1
310   if(ipar-2)350,330,320
320   ipar=ipar/4
      go to 310
330   do 340 i1=1,i1rng,2
      do 340 k1=i1,ntot,np1tw
      k2=k1+np1
      tempr=data(k2)
      tempi=data(k2+1)
      data(k2)=data(k1)-tempr
      data(k2+1)=data(k1+1)-tempi
      data(k1)=data(k1)+tempr
340   data(k1+1)=data(k1+1)+tempi
350   mmax=np1
360   if(mmax-ntwo/2)370,600,600
370   lmax=max0(np1tw,mmax/2)
      do 570 l=np1,lmax,np1tw
      m=l
      if(mmax-np1)420,420,380
380   theta=-twopi*REAL(l,EB)/REAL(4*mmax,EB)
      if(isign)400,390,390
390   theta=-theta
400   wr=cos(theta)
      wi=sin(theta)
410   w2r=wr*wr-wi*wi
      w2i=2._EB*wr*wi
      w3r=w2r*wr-w2i*wi
      w3i=w2r*wi+w2i*wr
420   do 530 i1=1,i1rng,2
      kmin=i1+ipar*m
      if(mmax-np1)430,430,440
430   kmin=i1
440   kdif=ipar*mmax
450   kstep=4*kdif
      if(kstep-ntwo)460,460,530
460   do 520 k1=kmin,ntot,kstep
      k2=k1+kdif
      k3=k2+kdif
      k4=k3+kdif
      if(mmax-np1)470,470,480
470   u1r=data(k1)+data(k2)
      u1i=data(k1+1)+data(k2+1)
      u2r=data(k3)+data(k4)
      u2i=data(k3+1)+data(k4+1)
      u3r=data(k1)-data(k2)
      u3i=data(k1+1)-data(k2+1)
      if(isign)471,472,472
471   u4r=data(k3+1)-data(k4+1)
      u4i=data(k4)-data(k3)
      go to 510
472   u4r=data(k4+1)-data(k3+1)
      u4i=data(k3)-data(k4)
      go to 510
480   t2r=w2r*data(k2)-w2i*data(k2+1)
      t2i=w2r*data(k2+1)+w2i*data(k2)
      t3r=wr*data(k3)-wi*data(k3+1)
      t3i=wr*data(k3+1)+wi*data(k3)
      t4r=w3r*data(k4)-w3i*data(k4+1)
      t4i=w3r*data(k4+1)+w3i*data(k4)
      u1r=data(k1)+t2r
      u1i=data(k1+1)+t2i
      u2r=t3r+t4r
      u2i=t3i+t4i
      u3r=data(k1)-t2r
      u3i=data(k1+1)-t2i
      if(isign)490,500,500
490   u4r=t3i-t4i
      u4i=t4r-t3r
      go to 510
500   u4r=t4i-t3i
      u4i=t3r-t4r
510   data(k1)=u1r+u2r
      data(k1+1)=u1i+u2i
      data(k2)=u3r+u4r
      data(k2+1)=u3i+u4i
      data(k3)=u1r-u2r
      data(k3+1)=u1i-u2i
      data(k4)=u3r-u4r
520   data(k4+1)=u3i-u4i
      kdif=kstep
      kmin=4*(kmin-i1)+i1
      go to 450
530   continue
      m=m+lmax
      if(m-mmax)540,540,570
540   if(isign)550,560,560
550   tempr=wr
      wr=(wr+wi)*rthlf
      wi=(wi-tempr)*rthlf
      go to 410
560   tempr=wr
      wr=(wr-wi)*rthlf
      wi=(tempr+wi)*rthlf
      go to 410
570   continue
      ipar=3-ipar
      mmax=mmax+mmax
      go to 360
!
!     main loop for factors not equal to two.  apply the twiddle factor
!     w=exp(isign*2*pi*sqrt(-1)*(j1-1)*(j2-j1)/(ifp1+ifp2)), then
!     perform a fourier transform of length ifact(iif), making use of
!     conjugate symmetries.
!
600   if(ntwo-np2)605,700,700
605   ifp1=ntwo
      iif=inon2
      np1hf=np1/2
610   ifp2=ifact(iif)*ifp1
      j1min=np1+1
      if(j1min-ifp1)615,615,640
615   do 635 j1=j1min,ifp1,np1
      theta=-twopi*REAL(j1-1,EB)/REAL(ifp2,EB)
      if(isign)625,620,620
620   theta=-theta
625   wstpr=cos(theta)
      wstpi=sin(theta)
      wr=wstpr
      wi=wstpi
      j2min=j1+ifp1
      j2max=j1+ifp2-ifp1
      do 635 j2=j2min,j2max,ifp1
      i1max=j2+i1rng-2
      do 630 i1=j2,i1max,2
      do 630 j3=i1,ntot,ifp2
      tempr=data(j3)
      data(j3)=data(j3)*wr-data(j3+1)*wi
630   data(j3+1)=tempr*wi+data(j3+1)*wr
      tempr=wr
      wr=wr*wstpr-wi*wstpi
635   wi=tempr*wstpi+wi*wstpr
640   theta=-twopi/REAL(ifact(iif),EB)
      if(isign)650,645,645
645   theta=-theta
650   wstpr=cos(theta)
      wstpi=sin(theta)
      j2rng=ifp1*(1+ifact(iif)/2)
      do 695 i1=1,i1rng,2
      do 695 i3=i1,ntot,np2
      j2max=i3+j2rng-ifp1
      do 690 j2=i3,j2max,ifp1
      j1max=j2+ifp1-np1
      do 680 j1=j2,j1max,np1
      j3max=j1+np2-ifp2
      do 680 j3=j1,j3max,ifp2
      jmin=j3-j2+i3
      jmax=jmin+ifp2-ifp1
      i=1+(j3-i3)/np1hf
      if(j2-i3)655,655,665
655   sumr=0._EB
      sumi=0._EB
      do 660 j=jmin,jmax,ifp1
659   sumr=sumr+data(j)
660   sumi=sumi+data(j+1)
      work(i)=sumr
      work(i+1)=sumi
      go to 680
665   iconj=1+(ifp2-2*j2+i3+j3)/np1hf
      j=jmax
      sumr=data(j)
      sumi=data(j+1)
      oldsr=0._EB
      oldsi=0._EB
      j=j-ifp1
670   tempr=sumr
      tempi=sumi
      sumr=twowr*sumr-oldsr+data(j)
      sumi=twowr*sumi-oldsi+data(j+1)
      oldsr=tempr
      oldsi=tempi
      j=j-ifp1
      if(j-jmin)675,675,670
675   tempr=wr*sumr-oldsr+data(j)
      tempi=wi*sumi
      work(i)=tempr-tempi
      work(iconj)=tempr+tempi
      tempr=wr*sumi-oldsi+data(j+1)
      tempi=wi*sumr
      work(i+1)=tempr+tempi
      work(iconj+1)=tempr-tempi
680   continue
      if(j2-i3)685,685,686
685   wr=wstpr
      wi=wstpi
      go to 690
686   tempr=wr
      wr=wr*wstpr-wi*wstpi
      wi=tempr*wstpi+wi*wstpr
690   twowr=wr+wr
      i=1
      i2max=i3+np2-np1
      do 695 i2=i3,i2max,np1
      data(i2)=work(i)
      data(i2+1)=work(i+1)
695   i=i+2
      iif=iif+1
      ifp1=ifp2
      if(ifp1-np2)610,700,700
!
!     complete a real transform in the 1st dimension, n even, by con-
!     jugate symmetries.
!
700   go to (900,800,900,701),icase
701   nhalf=n
      n=n+n
      theta=-twopi/REAL(n,EB)
      if(isign)703,702,702
702   theta=-theta
703   wstpr=cos(theta)
      wstpi=sin(theta)
      wr=wstpr
      wi=wstpi
      imin=3
      jmin=2*nhalf-1
      go to 725
710   j=jmin
      do 720 i=imin,ntot,np2
      sumr=(data(i)+data(j))/2._EB
      sumi=(data(i+1)+data(j+1))/2._EB
      difr=(data(i)-data(j))/2._EB
      difi=(data(i+1)-data(j+1))/2._EB
      tempr=wr*sumi+wi*difr
      tempi=wi*sumi-wr*difr
      data(i)=sumr+tempr
      data(i+1)=difi+tempi
      data(j)=sumr-tempr
      data(j+1)=-difi+tempi
720   j=j+np2
      imin=imin+2
      jmin=jmin-2
      tempr=wr
      wr=wr*wstpr-wi*wstpi
      wi=tempr*wstpi+wi*wstpr
725   if(imin-jmin)710,730,740
730   if(isign)731,740,740
731   do 735 i=imin,ntot,np2
735   data(i+1)=-data(i+1)
740   np2=np2+np2
      ntot=ntot+ntot
      j=ntot+1
      imax=ntot/2+1
745   imin=imax-2*nhalf
      i=imin
      go to 755
750   data(j)=data(i)
      data(j+1)=-data(i+1)
755   i=i+2
      j=j-2
      if(i-imax)750,760,760
760   data(j)=data(imin)-data(imin+1)
      data(j+1)=0._EB
      if(i-j)770,780,780
765   data(j)=data(i)
      data(j+1)=data(i+1)
770   i=i-2
      j=j-2
      if(i-imin)775,775,765
775   data(j)=data(imin)+data(imin+1)
      data(j+1)=0._EB
      imax=imin
      go to 745
780   data(1)=data(1)+data(2)
      data(2)=0._EB
      go to 900
!
!     complete a real transform for the 2nd or 3rd dimension by
!     conjugate symmetries.
!
800   if(i1rng-np1)805,900,900
805   do 860 i3=1,ntot,np2
      i2max=i3+np2-np1
      do 860 i2=i3,i2max,np1
      imin=i2+i1rng
      imax=i2+np1-2
      jmax=2*i3+np1-imin
      if(i2-i3)820,820,810
810   jmax=jmax+np2
820   if(idim-2)850,850,830
830   j=jmax+np0
      do 840 i=imin,imax,2
      data(i)=data(j)
      data(i+1)=-data(j+1)
840   j=j-2
850   j=jmax
      do 860 i=imin,imax,np0
      data(i)=data(j)
      data(i+1)=-data(j+1)
860   j=j-np0
!
!     end of loop on each dimension
!
900   np0=np1
      np1=np2
910   nprev=n

      ! reshape data back to 3D complex array
      
      !! for debug purposes (move to 920)
      !print *,size(data)
      !do i=1,size(data)
      !   print *,data(i)
      !enddo
      !stop
      
920   n=1
      do k=1,nn(3)
        do j=1,nn(2)
          do i=1,nn(1)
            data3(i,j,k)=cmplx(data(n),data(n+1),kind=DPC)
            n=n+2
          enddo
        enddo
      enddo                         
      return
      
END SUBROUTINE fourt_f90


SUBROUTINE ANALYTICAL_SOLUTION(NM)
IMPLICIT NONE
! Initialize flow variables with an analytical solution of the governing equations

INTEGER, INTENT(IN) :: NM
INTEGER :: I,J,K
REAL(EB) :: UU,WW

CALL POINT_TO_MESH(NM)

DO K=1,KBAR
   DO J=1,JBAR
      DO I=0,IBAR
         U(I,J,K) = 1._EB - 2._EB*COS(X(I))*SIN(ZC(K))
      ENDDO
   ENDDO
ENDDO
DO K=0,KBAR
   DO J=1,JBAR
      DO I=1,IBAR
         W(I,J,K) = 1._EB + 2._EB*SIN(XC(I))*COS(Z(K))
      ENDDO
   ENDDO
ENDDO
DO K=0,KBP1
   DO J=0,JBP1
      DO I=0,IBP1
         UU = 1._EB - 2._EB*COS(XC(I))*SIN(ZC(K))
         WW = 1._EB + 2._EB*SIN(XC(I))*COS(ZC(K))
         H(I,J,K) = -( COS(2._EB*XC(I)) + COS(2._EB*ZC(K)) ) + 0.5_EB*(UU**2+WW**2)
      ENDDO
   ENDDO
ENDDO

H(1:IBAR,1:JBAR,1:KBAR) = H(1:IBAR,1:JBAR,1:KBAR) - SUM(H(1:IBAR,1:JBAR,1:KBAR))/REAL(IBAR*JBAR*KBAR,EB)

END SUBROUTINE ANALYTICAL_SOLUTION


END MODULE TURBULENCE

