const std = @import("std");
const c = @cImport({
    @cDefine("WIN32_LEAN_AND_MEAN", "1");
    @cInclude("tensorflow/lite/c/c_api.h");
    @cInclude("edgetpu_c.h");
    @cInclude("string.h");
});

pub const DeviceType = enum(c_uint) {
    // The Device Types
    TypeApexPCI = c.EDGETPU_APEX_PCI,
    TypeApexUSB = c.EDGETPU_APEX_USB,
};

pub const Device = struct {
    deviceType: DeviceType,
    path: [*c]const u8,
};

pub fn EdgeTPU(device: Device, verbose: i32) *c.TfLiteDelegate {
    c.edgetpu_verbosity(verbose);
    return c.edgetpu_create_delegate(@intCast(c_uint, @enumToInt(device.deviceType)), device.path, null, 0);
}

pub fn listDevices(devices: *std.ArrayList(Device)) !void {
    // Fetch the list of devices
    var numDevices: usize = 0;
    var list = c.edgetpu_list_devices(&numDevices);
    defer c.edgetpu_free_devices(list);

    if (numDevices == 0) {
        return;
    }
    if (list == null) {
        return error.RuntimeError;
    }

    var devlist = @ptrCast([*]c.edgetpu_device, @alignCast(@alignOf(c.edgetpu_device), list))[0..numDevices];
    for (devlist) |item| {
        try devices.append(Device{ .deviceType = @intToEnum(DeviceType, item.type), .path = item.path });
    }
}

test "test delegate" {
    var allocator = std.testing.allocator;

    var devices = std.ArrayList(Device).init(allocator);
    defer devices.deinit();

    try listDevices(&devices);

    if (devices.items.len > 0) {
        _ = EdgeTPU(devices.items[0], 0);
    }
}
