import progressbar;

import ldc.libfuzzer;

int fuzzMain(in ubyte[] data)
{
    try
    {
        auto h = textUi(new Progressbar(0, 100), cast(string) data);
        return 0;
    }
    catch (Exception e)
    {
        return 0;
    }
}

mixin DefineTestOneInput!fuzzMain;
