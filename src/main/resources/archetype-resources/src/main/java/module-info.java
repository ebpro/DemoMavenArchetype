/**
 * A simple jigsaw module
 */
module $package.$artifactId {
    requires java.logging;
    requires static lombok;

    exports $package;
}
