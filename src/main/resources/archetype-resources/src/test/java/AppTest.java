package $package;

/*-
 * #%L
 * Demo Maven Archetype
 * %%
 * Copyright (C) 2020 - 2022 Université de Toulon
 * %%
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 * #L%
 */

import lombok.extern.slf4j.Slf4j;
import org.junit.jupiter.api.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.junit.jupiter.api.Assumptions.*;

/**
 * Unit test for simple App.
 */
@Slf4j
class AppTest {
    @BeforeAll
    static void init() {
        log.info("Once before all tests.");
    }

    @AfterAll
    static void close() {
        log.info("Once after all tests.");
    }

    @BeforeEach
    void prepare() {
        log.info("Before each test.");
    }

    @AfterEach
    void end() {
        log.info("After each test.");
    }

    @Test
        //@Disable
    void shouldAnswerWithTrue() {
        //Assumption to check that tests condition are ok (optional).
        //Notice the static import.
        assumeTrue(10 < 100);

        assertTrue(true);
    }

    @Test
    void checkException() {
        assertThrows(ArithmeticException.class, () -> {
            int x = 3 / 0;
        });
    }

}
