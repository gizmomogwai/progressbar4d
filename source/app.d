import std.stdio;

import progressbar;

void run(Progressbar pb)
{
    for (int i = 0; i < 30; ++i)
    {
        pb.step;
        std.stdio.write(pb.toString ~ "\r");
        stdout.flush;

        import core.thread;

        Thread.sleep(50.msecs);
    }
}

void runSpinner(T)(T[] ticks)
{
    run(new Progressbar(textUi(spinner(ticks, 1)), 100, 0));
    run(new Progressbar(textUi(spinner(ticks, -1)), 100, 0));
}

void main()
{
    auto pb = new Progressbar(textUi(new PadLeft(5, new Percentage, '.'),
            new Center(8, new Percentage, '.'), new Center(20, new Speed)), 100, 0);
    runSpinner(ROUND);
    runSpinner(TWO_ROUND);
    runSpinner(THREE_ROUND);
    runSpinner(INVERSE_ROUND);
    runSpinner(BULLETS);
    runSpinner(BOUNCING_BALL);
    runSpinner(FLIP);
    runSpinner(ARC);
    runSpinner(BOUNCING_BAR);
    runSpinner(MOON);
    runSpinner(CLOCK);
    runSpinner(DOTS);
    runSpinner(HLINE);
    runSpinner(BALL);
    runSpinner(POINTS);
    runSpinner(ARROWS);
    runSpinner(HFILL);
    runSpinner(VFILL);
    runSpinner(QUARTERS);
    runSpinner(QUARTER_SQUARES);
    runSpinner(TRIANGLES);
    runSpinner(HALVES);
    runSpinner(BRAILLE);
    runSpinner(UPDOWN);
    runSpinner(SLASH);
    run(pb);
}
