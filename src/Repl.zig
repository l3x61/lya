const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const eql = std.mem.eql;

const ansi = @import("ansi.zig");
const Interpreter = @import("Interpreter.zig");
const Lexer = @import("Lexer.zig");
const Parser = @import("Parser.zig");
const readLine = @import("readline.zig").readline;

const Line = std.ArrayList([]u8);
const Repl = @This();

allocator: Allocator,
lines: Line,
pub fn init(allocator: Allocator) Repl {
    return Repl{
        .allocator = allocator,
        .lines = Line.init(allocator),
    };
}

pub fn deinit(self: *Repl) void {
    for (self.lines.items) |line| self.allocator.free(line);
    self.lines.deinit();
}

pub fn run(self: *Repl) !void {
    const stdout = std.io.getStdOut().writer();
    const prompt = ansi.cyan ++ "> " ++ ansi.reset;

    var int = try Interpreter.init(self.allocator);
    defer int.deinit();

    while (true) {
        const line = try readLine(self.allocator, prompt);
        try self.lines.append(line);

        // TODO: should be built ins
        if (eql(u8, line, "exit")) break;
        if (eql(u8, line, "env")) int.env.debug();

        var parser = try Parser.init(self.allocator, line);
        const ast = parser.parse() catch continue;

        try stdout.print("{s}{s}{s}\n", .{ ansi.dimmed, ast, ansi.reset });

        const result = int.evaluate(ast) catch continue;
        try stdout.print("{s}\n", .{result});
    }
}
