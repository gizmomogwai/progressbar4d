/+ dub.sdl:
name "basic"
dependency "progressbar" path="../"
+/

import progressbar;
import std.stdio;

int main(string[] args)
{
    auto pb = new Progressbar(100, 0);
    auto ui = textUi(pb, "%=30P %p");
    pb.message("hello world");
    pb.step(10);
    writeln("123", ui.toString());
    pb.step(10);
    writeln("456", ui.toString);
    return 0;
}
