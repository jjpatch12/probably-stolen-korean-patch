using System;
using System.IO;
using System.IO.Compression;
using System.Text;
public static class PSKoreanDelta {
    static void Pump(Stream input, Stream output, long length, byte[] buffer) {
        while (length > 0) {
            int count = input.Read(buffer, 0, (int)Math.Min(length, buffer.Length));
            if (count == 0) throw new InvalidDataException("Unexpected end of patch/source.");
            output.Write(buffer, 0, count); length -= count;
        }
    }
    public static void Apply(string sourcePath, string patchPath, string outputPath) {
        using (Stream source = String.IsNullOrEmpty(sourcePath) ? (Stream)new MemoryStream() : File.OpenRead(sourcePath))
        using (var compressed = File.OpenRead(patchPath))
        using (var gzip = new GZipStream(compressed, CompressionMode.Decompress))
        using (var reader = new BinaryReader(gzip))
        using (var output = new FileStream(outputPath, FileMode.CreateNew, FileAccess.Write)) {
            if (Encoding.ASCII.GetString(reader.ReadBytes(8)) != "PSKRDP01") throw new InvalidDataException("Invalid patch header.");
            long expected = reader.ReadInt64();
            if (expected < 0 || expected > 2147483648L) throw new InvalidDataException("Unsupported file length.");
            byte[] buffer = new byte[1048576];
            while (true) {
                byte command = reader.ReadByte();
                if (command == 255) break;
                if (command != 0 && command != 1) throw new InvalidDataException("Invalid patch command.");
                long offset = command == 0 ? reader.ReadInt64() : 0;
                int length = reader.ReadInt32();
                if (length < 1 || output.Position + length > expected) throw new InvalidDataException("Patch length exceeds target.");
                if (command == 0) {
                    if (offset < 0 || offset > source.Length - length) throw new InvalidDataException("Source range exceeds original.");
                    source.Position = offset; Pump(source, output, length, buffer);
                } else Pump(gzip, output, length, buffer);
            }
            if (output.Length != expected || gzip.ReadByte() != -1) throw new InvalidDataException("Target length/trailing data mismatch.");
        }
    }
}
