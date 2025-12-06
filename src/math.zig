// Math utilities for Bidama Hajiki
// Vec3 and Mat4 for 3D transformations

const std = @import("std");

pub const Vec3 = struct {
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,

    pub fn sub(a: Vec3, b: Vec3) Vec3 {
        return .{ .x = a.x - b.x, .y = a.y - b.y, .z = a.z - b.z };
    }

    pub fn cross(a: Vec3, b: Vec3) Vec3 {
        return .{
            .x = a.y * b.z - a.z * b.y,
            .y = a.z * b.x - a.x * b.z,
            .z = a.x * b.y - a.y * b.x,
        };
    }

    pub fn dot(a: Vec3, b: Vec3) f32 {
        return a.x * b.x + a.y * b.y + a.z * b.z;
    }

    pub fn normalize(v: Vec3) Vec3 {
        const len = @sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
        if (len == 0) return v;
        return .{ .x = v.x / len, .y = v.y / len, .z = v.z / len };
    }
};

pub const Mat4 = struct {
    data: [16]f32 = [_]f32{0} ** 16,

    pub fn identity() Mat4 {
        var m = Mat4{};
        m.data[0] = 1;
        m.data[5] = 1;
        m.data[10] = 1;
        m.data[15] = 1;
        return m;
    }

    pub fn multiply(a: Mat4, b: Mat4) Mat4 {
        var result = Mat4{};
        for (0..4) |row| {
            for (0..4) |col| {
                var sum: f32 = 0;
                for (0..4) |k| {
                    sum += a.data[row * 4 + k] * b.data[k * 4 + col];
                }
                result.data[row * 4 + col] = sum;
            }
        }
        return result;
    }

    pub fn perspective(fov_radians: f32, aspect: f32, near: f32, far: f32) Mat4 {
        var m = Mat4{};
        const tan_half_fov = @tan(fov_radians / 2.0);
        m.data[0] = 1.0 / (aspect * tan_half_fov);
        m.data[5] = 1.0 / tan_half_fov;
        m.data[10] = -(far + near) / (far - near);
        m.data[11] = -1.0;
        m.data[14] = -(2.0 * far * near) / (far - near);
        return m;
    }

    pub fn lookAt(eye: Vec3, center: Vec3, up: Vec3) Mat4 {
        const f = Vec3.normalize(Vec3.sub(center, eye));
        const s = Vec3.normalize(Vec3.cross(f, up));
        const u = Vec3.cross(s, f);

        var m = Mat4.identity();
        m.data[0] = s.x;
        m.data[4] = s.y;
        m.data[8] = s.z;
        m.data[1] = u.x;
        m.data[5] = u.y;
        m.data[9] = u.z;
        m.data[2] = -f.x;
        m.data[6] = -f.y;
        m.data[10] = -f.z;
        m.data[12] = -Vec3.dot(s, eye);
        m.data[13] = -Vec3.dot(u, eye);
        m.data[14] = Vec3.dot(f, eye);
        return m;
    }

    pub fn rotateZ(angle: f32) Mat4 {
        var m = Mat4.identity();
        const cos_a = @cos(angle);
        const sin_a = @sin(angle);
        m.data[0] = cos_a;
        m.data[1] = sin_a;
        m.data[4] = -sin_a;
        m.data[5] = cos_a;
        return m;
    }
};
