import std.stdio;
import std.string;

import progressbar;

void run(ProgressbarUI pb)
{
    pb.step(0);
    pb.message("before start");
    writeln(pb.toString);

    for (int i = 0; i < 25; ++i)
    {
        pb.step(4);
        pb.message(" message %s".format(i));
        std.stdio.write(pb.toString ~ "\r");
        stdout.flush;

        import core.thread;

        Thread.sleep(50.msecs);
    }

    pb.step(0);
    pb.message("finished");
    writeln(pb.toString);
}

void runSpinner(T)(T[] ticks)
{
    // dfmt off
    run(textUi(new Progressbar(100, 0),
               new PadRight(30,
                   composite(
                       spinner(ticks, 1),
                       new Message)),
               new PercentageBar(20),
               new PadLeft(5, new Percentage)));
    // dfmt on
}

void main()
{

    /*
    auto pb = new Progressbar(textUi(new PadLeft(5, new Percentage, '.'),
            new Center(8, new Percentage, '.'), new Center(20, new Speed)), 100, 0);
    run(pb);
  */
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
}
