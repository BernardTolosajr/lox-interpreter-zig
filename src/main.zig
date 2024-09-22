const std = @import("std");
const ArrayList = std.ArrayList;

const PeekResult = struct {
    char: u8,
    index: u32,
};

const TokenType = enum {
    left_paren,
    righ_paren,
    left_brace,
    right_brace,
    comma,
    dot,
    minus,
    plus,
    semi_colon,
    slash,
    star,

    //
    bang,
    bang_equal,
    equal,
    equal_equal,
    greater,
    greater_equal,
    less,
    less_equal, // literals
    indetifier,
    string,
    number,

    // keywords
    @"and",
    class,
    @"else",
    false,
    fun,
    @"for",
    @"if",
    nil,
    @"or",
    print,
    @"return",
    super,
    this,
    true,
    @"var",
    @"while",

    eof,
};

const Token = struct {
    token_type: TokenType,
    lexeme: u8,
    line: u16,
    literal: []const u8,

    pub fn init(
        token_type: TokenType,
        lexeme: u8,
        line: u16,
        literal: []const u8,
    ) Token {
        return Token{
            .token_type = token_type,
            .lexeme = lexeme,
            .line = line,
            .literal = literal,
        };
    }

    pub fn to_string(self: Token) u8 {
        return self.token_type ++ " " ++ self.lexeme ++ " " ++ self.literal;
    }
};

pub fn main() !void {
    // Get the current working directory
    const cwd = std.fs.cwd();

    // try to open ./output assuming you did your 106_files exercise
    var output_dir = try cwd.openDir("output", .{});
    defer output_dir.close();

    // try to open the file
    const file = try output_dir.openFile("lox.txt", .{});
    defer file.close();

    var content: [500]u8 = undefined;

    try file.seekTo(0);
    const bytes_read = try file.readAll(&content);

    var start: u32 = 0;
    var current: u32 = 0;
    //var line: u32 = 1;

    const source = content[0..bytes_read];
    std.debug.print("len:{d} \n content:{s}\n", .{
        bytes_read,
        source, // change this line only
    });

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    // free the memory on exit
    defer arena.deinit();
    const allocator = arena.allocator();

    var tokens = ArrayList(Token).init(allocator);

    while (current < source.len) {
        start = current;
        current += 1;

        const c = peek(source, current) orelse break;

        switch (c) {
            '(' => {},
            ')' => {},
            '{' => {},
            '}' => {},
            ',' => {},
            '.' => {},
            '-' => {},
            ';' => {
                std.debug.print("adding token: {u} \n", .{c});
                try tokens.append(Token.init(TokenType.semi_colon, c, 1, ";"));
                continue;
            },
            '*' => {},
            '!' => {
                if (match('=', peek(source, current))) {
                    std.debug.print("adding token: {} \n", .{TokenType.bang_equal});
                    try tokens.append(Token.init(TokenType.bang_equal, c, 1, "!="));
                    continue;
                }
            },
            '=' => {
                if (match('=', peek(source, current))) {
                    std.debug.print("adding token: {} \n", .{TokenType.equal_equal});
                    try tokens.append(Token.init(TokenType.equal_equal, c, 1, "=="));
                    continue;
                }
            },
            '<' => {
                if (match('=', peek(source, current))) {
                    std.debug.print("adding token: {} \n", .{TokenType.less_equal});
                    try tokens.append(Token.init(TokenType.less_equal, c, 1, "<="));
                    continue;
                }
            },
            '>' => {
                if (match('=', peek(source, current))) {
                    std.debug.print("adding token: {} \n", .{TokenType.greater_equal});
                    try tokens.append(Token.init(TokenType.greater_equal, c, 1, ">="));
                    continue;
                }
            },
            '/' => {
                const p = peek(source, current);
                if (match('/', p)) {
                    _ = peekAhead(source, current);
                } else {
                    if (p != ' ') {
                        std.debug.print("adding token: {} \n", .{TokenType.slash});
                        try tokens.append(Token.init(TokenType.slash, c, 1, "/"));
                    }
                }
                continue;
            },
            ' ' => {
                continue;
            },
            '\n' => {
                continue;
            },
            '"' => {
                const ch = peekAhead(source, current);
                if (ch) |v| {
                    if (v.char == '"') {
                        const offset = v.index - current;
                        const literal = source[current + 1 .. current + offset]; // grab it
                        std.debug.print("current:{d} index:{d} offset:{d} \n", .{ current, v.index, offset });
                        std.debug.print("adding token: {} literal: {s}\n", .{ TokenType.string, literal });
                        try tokens.append(Token.init(TokenType.string, c, 1, literal));
                    }
                } else {
                    std.debug.print("null: {s} current: {d} \n", .{ source, start });
                    continue;
                }
            },
            else => {
                // catch all character
                if (isDigit(c)) {
                    // TODO: get number
                    //number(source, current);
                }
                continue;
            },
        }
    }
}

pub fn isDigit(c: u8) bool {
    return switch (c) {
        '0'...'9' => true,
        else => false,
    };
}

pub fn number(source: []u8, start: u32) void {
    const c = peekAhead(source, start).?;
    std.debug.print("source: number:{} \n", .{c.char});
}

pub fn peek(source: []u8, current: u32) ?u8 {
    const n = current + 1;
    if (n < source.len) {
        return source[current..n][0];
    }
    std.debug.print("peek: {s} current: {} next: {} \n", .{ "eof", current, n });
    return null;
}

pub fn peekAhead(source: []u8, start: u32) ?PeekResult {
    var current = start + 1; // advance 1 character ahead
    return while (true) : (current += 1) {
        const ch = peek(source, current).?;
        if (ch == '"') {
            std.debug.print("got string: {u} current: {d}\n", .{ ch, current });
            break PeekResult{ .char = ch, .index = current };
        }
        if (ch == '/') {
            std.debug.print("found slash /: {u} \n", .{ch});
            break PeekResult{ .char = ch, .index = current };
        }
        if (isDigit(ch)) {
            break PeekResult{ .char = ch, .index = current };
        }
        if (ch == '\n') break null;
    } else null;
}

pub fn match(expected: u8, lexeme: ?u8) bool {
    return expected == lexeme.?;
}

test "isdigit" {
    const d = isDigit('1');
    try std.testing.expectEqual(true, d);
}
