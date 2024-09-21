const std = @import("std");
const ArrayList = std.ArrayList;

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
                    if (v == '"') {
                        std.debug.print("adding token: {} \n", .{TokenType.string});
                        try tokens.append(Token.init(TokenType.string, c, 1, ""));
                        continue;
                    }
                } else {
                    std.debug.print("null: {s} current: {d} \n", .{ source, start });
                    continue;
                }
            },
            else => {
                continue;
            },
        }
    }
}

pub fn peek(source: []u8, current: u32) ?u8 {
    const n = current + 1;
    if (n < source.len) {
        return source[current..n][0];
    }
    std.debug.print("peek: {s} current: {} next: {} \n", .{ "eof", current, n });
    return null;
}

pub fn peekAhead(source: []u8, start: u32) ?u8 {
    return while (peek(source, start).? != '\n') {
        const ch = peek(source, start).?;
        if (ch == '"') {
            std.debug.print("found string literal: {u} \n", .{ch});
            break ch;
        }
        if (ch == '/') {
            std.debug.print("found slash /: {u} \n", .{ch});
            break ch;
        }
    } else null;
}

pub fn match(expected: u8, lexeme: ?u8) bool {
    return expected == lexeme.?;
}

test "text next lexeme" {
    var content = [2]u8{ '!', '=' };
    var start: u32 = 0;
    var current: u32 = 0;
    const source = content[0..2];
    while (current < 1) {
        start = current;
        current += 1;
        const c = source[start..current];
        switch (c[0]) {
            '!' => {
                try std.testing.expectEqual(true, match('=', peek(source, current)));
            },
            else => {},
        }
    }
}
