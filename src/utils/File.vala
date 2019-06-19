/* File.vala
 *
 * Copyright 2019 Paulo Queiroz <pvaqueiroz@gmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 * SPDX-License-Identifier: MIT
 */

public class Proton.File : Object {

    public GLib.File file { get; private set; }
    private GLib.FileInfo info;

    public File(string path) {
        Object(path: path);
    }

    public string path {
        owned get {
            return file.get_path();
        }
        set construct {
            load_file_for_path(value);
        }
    }

    private string _name;
    public  string  name {
        get {
            if (_name != null)
                return _name;
            _name = info.get_display_name();
            return _name;
        }
    }

    public string content_type {
        get {
            return info.get_content_type();
        }
    }

    private GLib.Icon? _icon = null;
    public GLib.Icon icon {
        get {
            if (_icon != null)
                return (_icon);
            _icon = GLib.ContentType.get_icon(info.get_content_type());
            return (_icon);
        }
    }

    public bool exists {
        get { return file.query_exists(); }
    }

    public bool is_directory {
        get {
            return (info.get_file_type() == FileType.DIRECTORY);
        }
    }

    public bool is_valid_textfile {
        get {
            if (info.get_is_backup())
                return false;

            if (info.get_file_type() == FileType.REGULAR &&
                ContentType.is_a(info.get_content_type(), "text/*"))
                return true;

            return false;
        }
    }

    public bool is_executable {
        get {
            try {
                return get_boolean_file_attribute(
                    GLib.FileAttribute.ACCESS_CAN_EXECUTE);
            } catch (GLib.Error error) {
                return false;
            }
        }
    }

    private bool get_boolean_file_attribute(string at) throws GLib.Error {
        var info = file.query_info(at, GLib.FileQueryInfoFlags.NONE);
        return info.get_attribute_boolean(at);
    }

    private void load_file_for_path(string path) {
        file = GLib.File.new_for_path(path);

        try {
            var query = GLib.FileAttribute.STANDARD_CONTENT_TYPE + "," +
                            GLib.FileAttribute.STANDARD_IS_BACKUP + "," +
                            GLib.FileAttribute.STANDARD_IS_HIDDEN + "," +
                            GLib.FileAttribute.STANDARD_DISPLAY_NAME + "," +
                            GLib.FileAttribute.STANDARD_TYPE;

            info = file.query_info(query, FileQueryInfoFlags.NONE);
        } catch (GLib.Error error) {
            // Supress error for inexistent file
            if (error.message.index_of("No such file or directory") == -1)
                warning(error.message);
        }
    }

    public void rename(string name) {
        try {
            file.set_display_name(name);
        } catch (GLib.Error error) {
            warning(error.message);
        }
    }

    public void trash() {
        try {
            file.trash();
        } catch (GLib.Error error) {
            warning(error.message);
        }
    }

    public async string? read_async() {

        if (!exists)
        {
            warning(@"File does not exist $(name)");
            return (null);
        }

        if (is_directory)
        {
            warning(@"Tried to read a directory $(name)");
            return (null);
        }

        /*
         * This may seem odd, but it is still faster than reading the file
         * line by line
         */

        var f = FileStream.open(path, "r");
        f.seek(0, FileSeek.END);
        long size = f.tell();
        f.rewind();

        var buf = new uint8[size];
        var sz = f.read(buf, 1);

        assert(sz == size);

        var s = (sz == 0) ? "" : (string)buf;
        s = s.make_valid((ssize_t)sz);

        return (s);
    }

    public async bool write_async(string text) {
        try {
            var ios = yield file.replace_readwrite_async(
                null, false, FileCreateFlags.NONE);

            var dos = new DataOutputStream(ios.output_stream);
            return dos.put_string(text);
        } catch (Error e) {
            warning(e.message);
            return false;
        }
    }

    public static bool equ(File? a, File? b) {
        if (a == null || b == null)
            return false;
        return a.file.equal(b.file);
    }
}

