package $package;

import lombok.extern.java.Log;

import java.text.MessageFormat;
import java.util.Arrays;
import java.util.Locale;
import java.util.ResourceBundle;

/**
 * A simple starting App ready for CI.
 */
@Log
public class App {
    /**
     * A resource bundle for I18N internationalisation.
     */
    private static ResourceBundle i18Nbundle = ResourceBundle.getBundle("demoI18N", Locale.getDefault());

    /**
     * A simple main() with log and local.
     *
     * @param args the CLI parameters
     */
    public static void main(String[] args) {
        log.info(MessageFormat.format(i18Nbundle.getString("helloworld"), Arrays.toString(args)));
    }

    /**
     * A sample method to illustrate tests.
     * @param x a positive int
     * @param y a positive int
     * @return the int value of the sum of x and y
     */
    public int add(int x, int y) {
        if (x < 0 || y < 0) throw new NumberFormatException(i18Nbundle.getString("parameter.format.positive"));
        return x + y;
    }
}

