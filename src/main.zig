const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const ChadType = enum { OBJ_INT, OBJ_PAIR };

const ChadObject = struct {
    marked: bool,
    c_type: ChadType, 
    value: union(ChadType) { 
        OBJ_INT: i64, 
        OBJ_PAIR: struct { 
            head: *ChadObject, 
            tail: *ChadObject }
    } 
};

const stack_size = 256;
const ChadStack = ArrayList(*ChadObject);
const SinglyLinkedList = std.SinglyLinkedList(*ChadObject);

const ChadVm = struct {
    stack: ChadStack,
    stack_size: usize,
    allocator: Allocator,
    allocated: SinglyLinkedList,

    const Self = @This();

    pub fn init(allocator: Allocator) ChadVm {
        return ChadVm{ 
            .stack = ChadStack.init(allocator), 
            .stack_size = stack_size, 
            .allocator = allocator,
            .allocated = SinglyLinkedList{}
        };
    }

    pub fn deinit(self: *Self) void {
        self.stack.deinit();

        while (self.allocated.first != null)
        {
            var poped = self.allocated.popFirst() orelse null;
            self.allocator.free(poped);
        }
    }

    pub fn new_object(self: *Self, _type: ChadType) !*ChadObject {
        var object = try self.allocator.create(ChadObject);

        self.allocated.prepend(&SinglyLinkedList.Node{.data = object});
        object.c_type = _type;
        object.marked = false;
        return object;
    }

    pub fn push_int(self: *Self, int_value: i64) !void {
        var object = try self.new_object(ChadType.OBJ_INT);
        object.value.OBJ_INT =  int_value;

        try self.push(object);
    }

    pub fn push_pair(self: *Self) !*ChadObject {
        var pair = self.new_object(ChadType.OBJ_PAIR);
        pair.tail = try self.pop();
        pair.head = try self.pop();

        try self.push(pair);
        return pair;
    }

    pub fn push(self: *Self, object: *ChadObject) !void {
        try self.stack.append(object);
    }

    pub fn pop(self: *Self) !*ChadObject {
        return try self.stack.pop();
    }

};

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();
    defer {
        const leaked = gpa.deinit();
        if (leaked) print("Mem leak detected \n", .{});
    }

    var vm: ChadVm = ChadVm.init(allocator);
    defer vm.deinit();

    try vm.push_int(1000);
    print("All your codebase are belong to us. \n", .{});
}
