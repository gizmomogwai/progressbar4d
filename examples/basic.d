import progressbar.parser;

import std.stdio;
import std.range;
import std.typecons;

int main(string[] args)
{
    auto pb = new Progressbar(100, 0);
    auto ui = textUi(pb, "abc%=30p");
    pb.message("hello world");
    for (int i = 0; i < 10; ++i)
    {
        pb.step(1);
        write(ui.toString() ~ "\r");
    }
    writeln(ui.toString());
    pb.step(20);
    writeln(ui.toString());
    pb.step(10);
    writeln(ui.toString);
    return 0;
}
