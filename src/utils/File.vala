/* File.vala
 *
 * The following code is a derivative work of the code from
 * https://github.com/elementary/code/blob/master/src/FolderManager/File.vala
 * which is also licensed under GNU General Public License version 3 of the
 * License, or (at your option) any later version.
 *
 * Copyright 2019 Paulo Queiroz <pvaqueiroz@gmail.com>
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
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Proton.File : Object
{
    public GLib.File        file { get; private set; }

    private FileInfo?  info = null;

    public File(string path)
    {
        Object(path: path);
    }

    public string path
    {
        owned get { return (this.file.get_path()); }
        construct set { this.load_file_for_path(value); }
    }

    public string name
    {
        owned get {
            if (this.info != null)
            {
                return (this.info.get_display_name());
            }

            string[] arr = this.path.split("/");
            if (arr.length > 0)
                return (arr[arr.length - 1]);

            return (this.path);
        }
    }

    public string? content_type
    {
        get {
            if (this.info != null)
                return (this.info.get_content_type());

            return (null);
        }
    }

    public GLib.Icon? icon
    {
        owned get {
            if (this.info != null)
                return (ContentType.get_icon(this.info.get_content_type()));

            return (null);
        }
    }

    public bool exists
    {
        get { return this.file.query_exists(); }
    }

    public bool is_directory
    {
        get {
            return (file.query_file_type(0, null) == FileType.DIRECTORY);
        }
    }

    public bool is_valid_textfile
    {
        get {
            if (this.info == null || this.info.get_is_backup())
                return (false);

            if (this.info.get_file_type() == FileType.REGULAR &&
                ContentType.is_a(this.info.get_content_type(), "text/*"))
                return (true);

            return (false);
        }
    }

    public bool is_executable
    {
        get {
            try
            {
                return (
                    get_boolean_file_attribute(FileAttribute.ACCESS_CAN_EXECUTE)
                );
            }
            catch (Error error)
            {
                warning("[File error] %s", error.message);
                return (false);
            }
        }
    }

    public bool is_empty
    {
        get {
            if (!this.is_directory)
                return (false);
            try
            {
                var d = Dir.open(this.path);
                string? s = null;
                while (null != (s = d.read_name()))
                    return (false);
                return (true);
            }
            catch
            {
                return (false);
            }
        }
    }

    private bool get_boolean_file_attribute(string at) throws Error
    {
        var inf = file.query_info(at, FileQueryInfoFlags.NONE);
        return (inf.get_attribute_boolean(at));
    }

    private void load_file_for_path(string path)
    {
        this.file = GLib.File.new_for_path(path);

        try
        {
            var query = FileAttribute.STANDARD_CONTENT_TYPE + "," +
                            FileAttribute.STANDARD_IS_BACKUP + "," +
                            FileAttribute.STANDARD_IS_HIDDEN + "," +
                            FileAttribute.STANDARD_DISPLAY_NAME + "," +
                            FileAttribute.STANDARD_TYPE;

            this.info = file.query_info(query, FileQueryInfoFlags.NONE);
        }
        catch (Error error)
        {
            // Supress error for inexistent file
            if (error.message.index_of("No such file or directory") == -1)
                warning("[File error] %s", error.message);
            else
                warning("[File error] Working with non-existent file %s", path);

            this.info = null;
        }
    }

    public void rename(string name) throws Error
    {
        this.file.set_display_name(name);
    }

    public void trash() throws Error
    {
        this.file.trash();
    }

    public async string? read_async()
    {
        if (!this.exists)
        {
            warning("File does not exist %s", this.name);
            return (null);
        }

        if (this.is_directory)
        {
            warning("Tried to read a directory %s", this.name);
            return (null);
        }

        /*
         * This may seem odd, but it is still faster than reading the file
         * line by line
         */

        var f = FileStream.open(this.path, "r");
        f.seek(0, FileSeek.END);
        long size = f.tell();
        f.rewind();

        var buf = new uint8[size];
        var sz = f.read(buf, 1);

        if (sz != size)
        {
            warning("[File error] invalid read size.");
            return (null);
        }

        var s = (sz == 0) ? "" : (string)buf;
        s = s.make_valid((ssize_t)sz);

        return (s);
    }

    // FIXME: This function should throw errors and let the caller handle them
    public async bool write_async(string text)
    {
        try
        {
            var ios = yield this.file.replace_readwrite_async(
                null, false, FileCreateFlags.NONE);

            var dos = new DataOutputStream(ios.output_stream);

            return (dos.put_string(text));
        }
        catch (Error e)
        {
            warning(e.message);
            return (false);
        }
    }

    public static bool equ(File? a, File? b)
    {
        if (a == null || b == null)
            return (false);

        return (a.file.equal(b.file));
    }
}

