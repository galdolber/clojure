package clojure;

import clojure.lang.RT;
import clojure.lang.Var;


public class Demo {

  public static void main(String[] args) throws Exception {
    RT.var("clojure.core", "map");
    Var.pushThreadBindings(RT
        .mapUniqueKeys(clojure.lang.Compiler.COMPILE_PATH, "target/gen", clojure.lang.Compiler.COMPILE_FILES, Boolean.TRUE));
    RT.load("clojure/core");
    RT.load("clojure/gal");
    Var.popThreadBindings();
    
//    Var.pushThreadBindings(
//        RT.mapUniqueKeys(RT.CURRENT_NS, RT.CURRENT_NS.deref(),
//            RT.UNCHECKED_MATH, RT.UNCHECKED_MATH.deref()));
//    gal__init.load();
//    System.out.println(RT.var("clojure.gal", "aaa").invoke());
//    Var.popThreadBindings();
  }
}