const
  HandshakeV0_4*: int32 = 0x400c2d20
  HandshakeJSON*: int32 = 0x7e6970c7

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
  QueryType* = enum
    START = 1
    CONTINUE = 2
    STOP = 3
    
  DatumType* = enum
    R_NULL
    R_BOOLEAN
    R_NUMBER
    R_STRING
    R_ARRAY
    R_OBJECT
    R_JSON
    R_BINARY
    R_TIME
    
  TermType* = enum
    DATUM = 1
    MAKE_ARRAY = 2
    MAKE_OBJ = 3
    JAVASCRIPT = 11
    ERROR = 12
    IMPLICIT_VAR = 13
    DB = 14
    TABLE = 15
    GET   = 16
    EQ = 17
    NE  = 18
    LT  = 19
    LE  = 20
    GT  = 21
    GE  = 22
    NOT = 23
    ADD = 24
    SUB = 25
    MUL = 26
    DIV = 27
    MOD = 28
    APPEND = 29
    SLICE  = 30
    GET_FIELD = 31
    HAS_FIELDS = 32
    PLUCK = 33
    WITHOUT = 34
    MERGE = 35
    BETWEEN_DEPRECATED = 36
    REDUCE = 37
    MAP = 38
    FILTER = 39
    CONCAT_MAP = 40
    ORDER_BY = 41
    DISTINCT = 42
    COUNT = 43
    UNION = 44
    NTH = 45
    INNER_JOIN = 48
    OUTER_JOIN = 49
    EQ_JOIN = 50
    COERCE_TO = 51
    TYPE_OF = 52
    UPDATE = 53
    DELETE = 54
    REPLACE = 55
    INSERT = 56
    DB_CREATE = 57
    DB_DROP = 58
    DB_LIST = 59
    TABLE_CREATE = 60
    TABLE_DROP = 61
    TABLE_LIST = 62
    FUNCALL = 64
    BRANCH = 65
    OR = 66
    AND = 67
    FOR_EACH = 68
    FUNC = 69
    SKIP  = 70
    LIMIT = 71
    ZIP = 72
    ASC = 73
    DESC = 74
    INDEX_CREATE = 75
    INDEX_DROP = 76
    INDEX_LIST = 77
    GET_ALL = 78
    INFO = 79
    PREPEND = 80
    SAMPLE = 81
    INSERT_AT = 82
    DELETE_AT = 83
    CHANGE_AT = 84
    SPLICE_AT = 85
    IS_EMPTY = 86
    OFFSETS_OF = 87
    SET_INSERT = 88
    SET_INTERSECTION = 89
    SET_UNION = 90
    SET_DIFFERENCE = 91
    DEFAULT = 92
    CONTAINS = 93
    KEYS = 94
    DIFFERENCE = 95
    WITH_FIELDS = 96
    MATCH = 97
    JSON = 98
    ISO8601 = 99
    TO_ISO8601 = 100
    EPOCH_TIME = 101
    TO_EPOCH_TIME = 102
    NOW = 103
    IN_TIMEZONE = 104
    DURING = 105
    DATE = 106
    MONDAY = 107
    TUESDAY = 108
    WEDNESDAY = 109
    THURSDAY = 110
    FRIDAY = 111
    SATURDAY = 112
    SUNDAY = 113
    JANUARY = 114
    FEBRUARY = 115
    MARCH = 116
    APRIL = 117
    MAY = 118
    JUNE = 119
    JULY = 120
    AUGUST = 121
    SEPTEMBER = 122
    OCTOBER = 123
    NOVEMBER = 124
    DECEMBER = 125
    TIME_OF_DAY = 126
    TIMEZONE = 127
    YEAR = 128
    MONTH = 129
    DAY = 130
    DAY_OF_WEEK = 131
    DAY_OF_YEAR = 132
    HOURS = 133
    MINUTES = 134
    SECONDS = 135
    TIME = 136
    LITERAL = 137
    SYNC = 138
    INDEX_STATUS = 139
    INDEX_WAIT = 140
    UPCASE = 141
    DOWNCASE = 142
    OBJECT = 143
    GROUP = 144
    SUM = 145
    AVG = 146
    MIN = 147
    MAX = 148
    SPLIT = 149
    UNGROUP = 150
    RANDOM = 151
    CHANGES = 152
    HTTP = 153
    ARGS = 154
    BINARY = 155
    INDEX_RENAME = 156
    GEOJSON = 157
    TO_GEOJSON = 158
    POINT = 159
    LINE = 160
    POLYGON = 161
    DISTANCE = 162
    INTERSECTS = 163
    INCLUDES = 164
    CIRCLE = 165
    GET_INTERSECTING = 166
    FILL = 167
    GET_NEAREST = 168
    UUID = 169
    BRACKET = 170
    POLYGON_SUB = 171
    TO_JSON_STRING = 172
    RANGE = 173
    CONFIG = 174
    STATUS = 175
    RECONFIGURE = 176
    WAIT = 177
    REBALANCE = 179
    MINVAL = 180
    MAXVAL = 181    
    BETWEEN = 182
    FLOOR = 183
    CEIL = 184
    ROUND = 185
