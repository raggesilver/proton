/* File.vala
 *
 * Copyright 2020 Paulo Queiroz
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

public class Proton.File : Object {
    private FileInfo? info = null;

    public GLib.File file { get; private set; }

    public string path {
        owned get {
            return (this.file.get_path());
        }
    }

    public string name {
        owned get {
            if (this.info != null) {
                return (this.info.get_display_name());
            }
            string[] arr = this.path.split(Path.DIR_SEPARATOR_S);
            if (arr.length > 0) {
                return (arr[arr.length - 1]);
            }
            return (this.path);
        }
        // TODO: set {} => quick way to rename the file
    }

    public string? content_type {
        get {
            if (this.info != null) {
                return (this.info.get_content_type());
            }
            return (null);
        }
    }

    public GLib.Icon? icon {
        owned get {
            if (this.info != null) {
                return (ContentType.get_icon(this.info.get_content_type()));
            }
            return (null);
        }
    }

    public bool exists {
        get {
            return (FileUtils.test(this.path, FileTest.EXISTS));
        }
    }

    public bool is_directory {
        get {
            return (FileUtils.test(this.path, FileTest.IS_DIR));
        }
    }

    public bool is_executable {
        get {
            return (FileUtils.test(this.path, FileTest.IS_EXECUTABLE));
        }
    }

    public bool is_link {
        get {
            return (FileUtils.test(this.path, FileTest.IS_SYMLINK));
        }
    }

    public bool is_regular {
        get {
            return (FileUtils.test(this.path, FileTest.IS_REGULAR));
        }
    }

    public bool is_valid_text_file {
        get {
            if (this.info == null || this.info.get_is_backup()) {
                return (false);
            }
            return (
                this.is_regular && ContentType.is_a(this.content_type, "text/*")
            );
        }
    }

    public bool is_empty {
        get {
            if (!this.is_directory) {
                return (false);
            }
            try {
                var d = Dir.open(this.path);
                string? n = d.read_name();

                return (n == null);
            }
            catch (Error e) {
                warning(e.message);
                return (false);
            }
        }
    }

    public File(string path) {
        Object();
        this.load_file_for_path(path);
    }

    // TODO: public File.build_path(string path, ...) {}

    private void load_file_for_path(string path) {
        this.file = GLib.File.new_for_path(path);

        if (!this.exists) {
            return;
        }
        this.internal_get_info();
    }

    private void internal_get_info() {
        try {
            this.info = this.file.query_info("standard::*",
                                             FileQueryInfoFlags.NONE);
        }
        catch (Error e) {
            warning(e.message);
        }
    }

    public void get_info(string? query = "standard::*") throws Error {
        this.info = this.file.query_info(query, FileQueryInfoFlags.NONE);
    }

    public void rename(string name) throws Error {
        var f = this.file.set_display_name(name);

        this.file = f;
        this.internal_get_info();
    }

    public bool trash() throws Error {
        return (this.file.trash());
    }

    public async string? read_async(Cancellable? cancellable = null) {
        if (!this.exists || this.is_directory) {
            return (null);
        }

        string? res = null;

        new Thread<bool>("proton-file-read-async", () => {
            var f = FileStream.open(this.path, "r");
            long size;

            if (f == null) {
                return (false);
            }

            f.seek(0, FileSeek.END);
            size = f.tell();
            f.rewind();

            var buf = new uint8[size];
            var sz = f.read(buf, 1);

            if (sz != size) {
                warning("[Proton.File.read_async] invalid read size");
            }

            res = (sz == 0) ? "" : (string)buf;
            res = res.make_valid((ssize_t)sz);

            Idle.add(this.read_async.callback);
            return (true);
        });

        yield;
        return (res);
    }

    public async bool write_async(string text) throws Error {
        bool res = false;
        Error? err = null;

        new Thread<bool>("proton-file-write-async", () => {
            try {
                var ios = this.file.replace_readwrite(
                    null, false, FileCreateFlags.NONE
                );
                var dos = new DataOutputStream(ios.output_stream);

                res = dos.put_string(text);
            }
            catch (Error e) {
                err = e;
            }
            Idle.add(this.write_async.callback);
            return (true);
        });

        yield;

        if (err != null) {
            throw err;
        }

        return (res);
    }

    // TODO: evaluate, why does this exist?
    public static bool equ(File? a, File? b) {
        if (a == null || b == null) {
            return (false);
        }
        return (a.file.equal(b.file));
    }
}
