import std.stdio;
import std.string;

import progressbar;

void run(ProgressbarUI pb)
{
    pb.step(0);
    pb.message("before start");
    writeln(pb.toString);

    for (int i = 0; i < 100; ++i)
    {
        pb.step(1);
        pb.message("message %s".format(i));
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
    [
               new SeparatorPart("|"),
               new PadRightPart(30,
                   composite(
                       spinner(ticks, 1),
                       new SeparatorPart(" - "),
                       new MessagePart),
               ),
               new SeparatorPart(" |"),
               new PercentageBarPart(20),
               new SeparatorPart("| "),
               new PadLeftPart(5, new PercentagePart),
               new SeparatorPart("% | "),
               new PadLeftPart(8, new RestDurationPart),
               new SeparatorPart(" | "),
               new PadLeftPart(8, new TotalDurationPart),
               new SeparatorPart(" |"),
               ]
        ));
    // dfmt on
}

void main()
{
    run(textUi(new Progressbar(100, 0), "|%<50(%s - %m) |%=30P| %p | %r | %t |"));
    run(textUi(new Progressbar(100, 0), "|%>50(%s - %m - %m) |%=30P| %p | %r | %t |"));
    run(textUi(new Progressbar(100, 0), "|%=50(%s - %m - %m) |%=30P| %p | %r | %t |"));
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
