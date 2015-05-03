const
  HandshakeV0_4* = 0x400c2d20
  HandshakeJSON* = 0x7e6970c7

type
  ResponseType* = enum
    SUCCESS_ATOM      = 1,  ## Query returned a single RQL datatype.
    SUCCESS_SEQUENCE  = 2, ## Query returned a sequence of RQL datatypes.
    SUCCESS_PARTIAL   = 3, ## Query returned a partial sequence of RQL
                           ## datatypes.  If you send a [CONTINUE] query with
                           ## the same token as this response, you will get
                           ## more of the sequence.  Keep sending [CONTINUE]
                           ## queries until you get back [SUCCESS_SEQUENCE].
    WAIT_COMPLETE     = 4, ## A [NOREPLY_WAIT] query completed.

    # These response types indicate failure.
    CLIENT_ERROR  = 16, ## Means the client is buggy.  An example is if the
                        ## client sends a malformed protobuf, or tries to
                        ## send [CONTINUE] for an unknown token.
    COMPILE_ERROR = 17, ## Means the query failed during parsing or type
                        ## checking.  For example, if you pass too many
                        ## arguments to a function.
    RUNTIME_ERROR = 18  ## Means the query failed at runtime.  An example is
                        ## if you add together two values from a table, but
                        ## they turn out at runtime to be booleans rather
                        ## than numbers.
