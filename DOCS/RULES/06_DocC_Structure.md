Adding structure to your documentation pages | Apple Developer Documentation
Overview

By default, when DocC generates documentation for a project, it creates a top-level page that groups the symbols by their kind. For frameworks and packages, DocC includes the public symbols, and for app targets, it includes both the internal and public symbols. You can then provide additional context to explain how your app or framework works and how different symbols relate to each other.

For a more tailored learning experience, use one or more of the following approaches:

Customize the main landing page for your documentation catalog to introduce your technology and organize its top-level symbols.

Add symbol-specific extension files that organize nested symbols, such as methods and properties.

Use collections to group multiple symbols and introduce hierarchy to the navigation of your documentation pages.

For more information about how to use DocC for adding structure to the documentation, see Adding Structure to Your Documentation Pages at Swift.org.

Customize your documentation’s landing page

A landing page provides an overview of your technology, introduces important terms, and organizes the resources within your documentation catalog — the files that enrich your source documentation comments. The landing page is an opportunity for you to ease the reader’s learning path, discuss key features of your technology, and offer motivation for the reader to return to when they need it.

Two side-by-side images of a framework’s top-level page. The image on the left shows the basic empty page that DocC generates by default. The image on the right shows a customized landing page that includes additional content and a color graphic.

When you add a documentation catalog to your project, Xcode automatically includes an empty landing page. For more information, see Documenting apps, frameworks, and packages.

If you need to manually add a landing page to your documentation catalog, follow these steps:

In Xcode, select your documentation catalog in the Project navigator.

Choose File > New > File from Template.

Select the Empty template in the Documentation section and click Next.

Enter a filename and click Create. Xcode creates a Markdown file that contains only a placeholder for the page title.

A screenshot of Xcode’s file template chooser with the Empty template in a selected state in the Documentation section.

Use a filename that matches the target’s product module name. For example, for the SlothCreator framework, the filename is SlothCreator.md.

Note

For targets with spaces in the product name, Xcode replaces the spaces with underscores in the product module name. To find the product module name in an Xcode project, select the target in the project editor, click the Build Settings tab, and enter Product Module Name in the search field.

Arrange top-level symbols using topic groups

By default, DocC arranges the symbols in your project according to their kind. For example, the compiler generates topic groups for classes, structures, protocols, and so forth. You then add information to explain the relationships between those symbols.

To help readers more easily navigate your framework, arrange symbols into groups with meaningful names. Place important symbols higher on the page, and nest supporting symbols inside other symbols. Use group names that are unique, mutually exclusive, and clear. Experiment with different arrangements to find what works best for you.

Two side-by-side images that show different arrangements of a framework’s top-level symbols. The image on the left shows the basic arrangement that DocC generates by default. The image on the right shows a custom arrangement that includes more descriptive headers and content.

To override the default organization and manually arrange the top-level symbols in your technology, add a Topics section to your technology’s landing page. Below any content already in the Markdown file, add a double hash (##), a space, and the Topics keyword.

After the Topics header, create a named section for each group using a triple hash (###), and add one or more top-level symbols to each section. Precede each symbol with a dash (-) and encapsulate it in a pair of double backticks (``) .

## Topics


### Creating sloths


- ``SlothGenerator``
- ``NameGenerator``
- ``Habitat``


### Caring for sloths


- ``Activity``
- ``CareSchedule``
- ``FoodGenerator``
- ``Sloth/Food``
DocC uses the double backtick format to create symbol links, and to add the symbol’s type information and summary. For more information, see Formatting Your Documentation Content Swift.org.

When you rebuild your documentation, the documentation viewer reflects these organizational changes in the navigation pane and on the landing page, as the image above shows.

Arrange nested symbols in extension files

Not all symbols appear on the top-level landing page. For example, classes and structures define methods and properties, and in some cases, nested classes or structures introduce additional levels of hierarchy.

As with the top-level landing page, DocC generates default topic groups for nested symbols according to their type. Use extension files to override this default organization and provide a more appropriate structure for your symbols.

Two side-by-side images that show different arrangements of a symbol’s methods and properties. The image on the left shows the basic arrangement that DocC generates by default. The image on the right shows a custom arrangement that includes more descriptive headers and content.

To add an extension file to your documentation catalog for a specific symbol, do the following:

In Xcode, select your documentation catalog in the Project navigator.

Choose File > New > File from Template.

Select the Extension File template in the Documentation section and click Next.

Enter the symbol name as the filename and click Create.

A screenshot of Xcode’s file template chooser with the Extension File template in a selected state in the Documentation section.

In the extension file, replace the Symbol placeholder with the absolute path to the symbol. The absolute path is the target’s product module name followed by the symbol name.

# ``SlothCreator/Sloth``
The Extension File template includes a Topics section with a single named group, ready for you to fill out. Alternatively, if your documentation catalog already contains an extension file for a specific symbol, add a Topics section to it by following the steps in the previous section.

As with the landing page, create named sections for each topic group using a triple hash (###), and add the necessary symbols to each section using the double backtick (``) syntax.

# ``SlothCreator/Sloth``


## Topics


### Creating a sloth


- ``init(name:color:power:)``
- ``SlothGenerator``


### Activities


- ``eat(_:quantity:)``
- ``sleep(in:for:)``


### Schedule


- ``schedule``
Tip

Use a symbol’s full path to include it from elsewhere in the documentation hierarchy.

After you arrange nested symbols in an extension file, choose Product > Build Documentation to compile your changes and review them in Xcode’s documentation viewer.
