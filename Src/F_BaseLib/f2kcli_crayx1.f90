! F2KCLI : Fortran 200x Command Line Interface
! copyright Interactive Software Services Ltd. 2001
! For conditions of use see manual.txt
!
! Platform    : Unix/Linux
! Compiler    : Any Fortran 9x compiler supporting IARGC/GETARG
!               which counts the first true command line argument
!               after the program name as argument number one.
!               (Excludes compilers which require a special USE
!               statement to make IARGC/GETARG available).
! To compile  : f90 -c f2kcli.f90
!               (exact compiler name will vary)
! Implementer : Lawson B. Wakefield, I.S.S. Ltd.
! Date        : February 2001
!
      MODULE f2kcli
!
      CONTAINS
!
      SUBROUTINE GET_COMMAND(COMMAND,LENGTH,STATUS)
!
! Description. Returns the entire command by which the program was
!   invoked.
!
! Class. Subroutine.
!
! Arguments.
! COMMAND (optional) shall be scalar and of type default character.
!   It is an INTENT(OUT) argument. It is assigned the entire command
!   by which the program was invoked. If the command cannot be
!   determined, COMMAND is assigned all blanks.
! LENGTH (optional) shall be scalar and of type default integer. It is
!   an INTENT(OUT) argument. It is assigned the significant length
!   of the command by which the program was invoked. The significant
!   length may include trailing blanks if the processor allows commands
!   with significant trailing blanks. This length does not consider any
!   possible truncation or padding in assigning the command to the
!   COMMAND argument; in fact the COMMAND argument need not even be
!   present. If the command length cannot be determined, a length of
!   0 is assigned.
! STATUS (optional) shall be scalar and of type default integer. It is
!   an INTENT(OUT) argument. It is assigned the value 0 if the
!   command retrieval is sucessful. It is assigned a processor-dependent
!   non-zero value if the command retrieval fails.
!
      CHARACTER(LEN=*), INTENT(OUT), OPTIONAL :: COMMAND
      INTEGER         , INTENT(OUT), OPTIONAL :: LENGTH
      INTEGER         , INTENT(OUT), OPTIONAL :: STATUS
!
      INTEGER                   :: IARG,NARG,IPOS
      INTEGER            , SAVE :: LENARG
      CHARACTER(LEN=2000), SAVE :: ARGSTR
      LOGICAL            , SAVE :: GETCMD = .TRUE.
      INTEGER IERR, IL
!
! The following INTEGER/EXTERNAL declarations of IARGC should not
! really be necessary. However, at least one compiler (PGI) comments
! on their absence, so they are included for completeness.
!
      INTEGER :: IPXFARGC
      EXTERNAL   IPXFARGC
!
! Under Unix we must reconstruct the command line from its constituent
! parts. This will not be the original command line. Rather it will be
! the expanded command line as generated by the shell.
!
      IF (GETCMD) THEN
          NARG = IPXFARGC()
          IF (NARG > 0) THEN
              IPOS = 1
              DO IARG = 1,NARG
                CALL PXFGETARG(IARG,ARGSTR(IPOS:),IL,IERR)
                LENARG = LEN_TRIM(ARGSTR)
                IPOS   = LENARG + 2
                IF (IPOS > LEN(ARGSTR)) EXIT
              END DO
          ELSE
              ARGSTR = ' '
              LENARG = 0
          ENDIF
          GETCMD = .FALSE.
      ENDIF
      IF (PRESENT(COMMAND)) COMMAND = ARGSTR
      IF (PRESENT(LENGTH))  LENGTH  = LENARG
      IF (PRESENT(STATUS))  STATUS  = 0
      RETURN
      END SUBROUTINE GET_COMMAND
!
      INTEGER FUNCTION COMMAND_ARGUMENT_COUNT()
!
! Description. Returns the number of command arguments.
!
! Class. Inquiry function
!
! Arguments. None.
!
! Result Characteristics. Scalar default integer.
!
! Result Value. The result value is equal to the number of command
!   arguments available. If there are no command arguments available
!   or if the processor does not support command arguments, then
!   the result value is 0. If the processor has a concept of a command
!   name, the command name does not count as one of the command
!   arguments.
!
! The following INTEGER/EXTERNAL declarations of IARGC should not
! really be necessary. However, at least one compiler (PGI) comments
! on their absence, so they are included for completeness.
!
      INTEGER :: IPXFARGC
      EXTERNAL   IPXFARGC
!
      COMMAND_ARGUMENT_COUNT = IPXFARGC()
      RETURN
      END FUNCTION COMMAND_ARGUMENT_COUNT
!
      SUBROUTINE GET_COMMAND_ARGUMENT(NUMBER,VALUE,LENGTH,STATUS)
!
! Description. Returns a command argument.
!
! Class. Subroutine.
!
! Arguments.
! NUMBER shall be scalar and of type default integer. It is an
!   INTENT(IN) argument. It specifies the number of the command
!   argument that the other arguments give information about. Useful
!   values of NUMBER are those between 0 and the argument count
!   returned by the COMMAND_ARGUMENT_COUNT intrinsic.
!   Other values are allowed, but will result in error status return
!   (see below).  Command argument 0 is defined to be the command
!   name by which the program was invoked if the processor has such
!   a concept. It is allowed to call the GET_COMMAND_ARGUMENT
!   procedure for command argument number 0, even if the processor
!   does not define command names or other command arguments.
!   The remaining command arguments are numbered consecutively from
!   1 to the argument count in an order determined by the processor.
! VALUE (optional) shall be scalar and of type default character.
!   It is an INTENT(OUT) argument. It is assigned the value of the
!   command argument specified by NUMBER. If the command argument value
!   cannot be determined, VALUE is assigned all blanks.
! LENGTH (optional) shall be scalar and of type default integer.
!   It is an INTENT(OUT) argument. It is assigned the significant length
!   of the command argument specified by NUMBER. The significant
!   length may include trailing blanks if the processor allows command
!   arguments with significant trailing blanks. This length does not
!   consider any possible truncation or padding in assigning the
!   command argument value to the VALUE argument; in fact the
!   VALUE argument need not even be present. If the command
!   argument length cannot be determined, a length of 0 is assigned.
! STATUS (optional) shall be scalar and of type default integer.
!   It is an INTENT(OUT) argument. It is assigned the value 0 if
!   the argument retrieval is sucessful. It is assigned a
!   processor-dependent non-zero value if the argument retrieval fails.
!
! NOTE
!   One possible reason for failure is that NUMBER is negative or
!   greater than COMMAND_ARGUMENT_COUNT().
!
      INTEGER         , INTENT(IN)            :: NUMBER
      CHARACTER(LEN=*), INTENT(OUT), OPTIONAL :: VALUE
      INTEGER         , INTENT(OUT), OPTIONAL :: LENGTH
      INTEGER         , INTENT(OUT), OPTIONAL :: STATUS
!
!  A temporary variable for the rare case case where LENGTH is
!  specified but VALUE is not. An arbitrary maximum argument length
!  of 1000 characters should cover virtually all situations.
!
      CHARACTER(LEN=1000) :: TMPVAL
      INTEGER     IERR, IL
!
! The following INTEGER/EXTERNAL declarations of IARGC should not
! really be necessary. However, at least one compiler (PGI) comments
! on their absence, so they are included for completeness.
!
      INTEGER :: IPXFARGC
      EXTERNAL   IPXFARGC
!
! Possible error codes:
! 1 = Argument number is less than minimum
! 2 = Argument number exceeds maximum
!
      IF (NUMBER < 0) THEN
          IF (PRESENT(VALUE )) VALUE  = ' '
          IF (PRESENT(LENGTH)) LENGTH = 0
          IF (PRESENT(STATUS)) STATUS = 1
          RETURN
      ELSE IF (NUMBER > IPXFARGC()) THEN
          IF (PRESENT(VALUE )) VALUE  = ' '
          IF (PRESENT(LENGTH)) LENGTH = 0
          IF (PRESENT(STATUS)) STATUS = 2
          RETURN
      END IF
!
! Get the argument if VALUE is present
!
      IF (PRESENT(VALUE)) CALL PXFGETARG(NUMBER,VALUE,IL,IERR)
!
! The LENGTH option is fairly pointless under Unix.
! Trailing spaces can only be specified using quotes.
! Since the command line has already been processed by the
! shell before the application sees it, we have no way of
! knowing the true length of any quoted arguments. LEN_TRIM
! is used to ensure at least some sort of meaningful result.
!
      IF (PRESENT(LENGTH)) THEN
          IF (PRESENT(VALUE)) THEN
              LENGTH = LEN_TRIM(VALUE)
          ELSE
              CALL PXFGETARG(NUMBER,TMPVAL,IL,IERR)
              LENGTH = LEN_TRIM(TMPVAL)
          END IF
      END IF
!
! Since GETARG does not return a result code, assume success
!
      IF (PRESENT(STATUS)) STATUS = 0
      RETURN
      END SUBROUTINE GET_COMMAND_ARGUMENT

      SUBROUTINE GET_ENVIRONMENT_VARIABLE(NAME,VALUE,LENGTH,STATUS,TRIM_NAME)
      INTEGER, INTENT(OUT), OPTIONAL :: LENGTH
      CHARACTER(LEN=*), INTENT(IN)   :: NAME
      CHARACTER(LEN=*), INTENT(OUT), OPTIONAL :: VALUE
      LOGICAL, INTENT(IN), OPTIONAL :: TRIM_NAME
      INTEGER, INTENT(OUT), OPTIONAL :: STATUS
!
      CHARACTER(LEN=2048) :: TMPVAL
      INTEGER :: LL, IL, IERR

      LL = LEN_TRIM(NAME)
      IF ( PRESENT(TRIM_NAME) ) THEN
        IF ( .NOT. TRIM_NAME ) LL = LEN(NAME)
      END IF

      CALL PXFGETENV(NAME(1:LL), LL, TMPVAL, IL, IERR)
      IF ( IERR /= 0 ) THEN
         IF ( PRESENT(STATUS) ) STATUS = 1
         IF ( PRESENT(STATUS) ) STATUS = 1
         IF ( PRESENT(LENGTH) ) LENGTH = 0
         IF ( PRESENT(VALUE)  ) VALUE  = ' '
      ELSE
        IF ( PRESENT(VALUE)  ) VALUE  = TMPVAL
        IF ( PRESENT(LENGTH) ) LENGTH = LEN_TRIM(TMPVAL)
        IF ( PRESENT(STATUS) ) STATUS = 0
      END IF

      END SUBROUTINE GET_ENVIRONMENT_VARIABLE

      END MODULE f2kcli
