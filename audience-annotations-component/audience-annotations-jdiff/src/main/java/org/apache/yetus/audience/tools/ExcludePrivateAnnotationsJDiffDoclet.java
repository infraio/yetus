/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.apache.yetus.audience.tools;

import com.sun.javadoc.DocErrorReporter;
import com.sun.javadoc.LanguageVersion;
import com.sun.javadoc.RootDoc;

import jdiff.JDiff;

import org.apache.yetus.audience.InterfaceAudience;
import org.apache.yetus.audience.InterfaceStability;

/**
 * A <a href="https://java.sun.com/javase/6/docs/jdk/api/javadoc/doclet/">Doclet</a>
 * for excluding elements that are annotated with
 * {@link org.apache.yetus.audience.InterfaceAudience.Private} or
 * {@link org.apache.yetus.audience.InterfaceAudience.LimitedPrivate}.
 * It delegates to the JDiff Doclet, and takes the same options.
 */
@InterfaceAudience.Public
@InterfaceStability.Evolving
public class ExcludePrivateAnnotationsJDiffDoclet {

  public static LanguageVersion languageVersion() {
    return LanguageVersion.JAVA_1_5;
  }

  public static boolean start(RootDoc root) {
    return JDiff.start(RootDocProcessor.process(root));
  }

  public static int optionLength(String option) {
    Integer length = StabilityOptions.optionLength(option);
    if (length != null) {
      return length;
    }
    return JDiff.optionLength(option);
  }

  public static boolean validOptions(String[][] options,
      DocErrorReporter reporter) {
    StabilityOptions.validOptions(options, reporter);
    String[][] filteredOptions = StabilityOptions.filterOptions(options);
    return JDiff.validOptions(filteredOptions, reporter);
  }
}
