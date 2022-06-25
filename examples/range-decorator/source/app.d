import std.range;
import core.thread;
import core.time;
import std.random;
import progressbar;

int main(string[] args)
{
    auto rnd = Random(unpredictableSeed);
    foreach (i; iota(100).withTextUi("some progress: |%=30P| (%S/s)"))
    {
        Thread.sleep(dur!("msecs")(uniform(0, 50, rnd)));
    }
    return 0;
}
