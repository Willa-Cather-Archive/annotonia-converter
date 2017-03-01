# annotonia-converter
Alters Cather TEI letters with annotations from the annotonia

## Contents

- [Overview](#overview)
- [First Time Setup](#initial-setup)
- [Generating Annotated Files](#generating-annotated-files)
- [Outputting Annotations TEI](#outputting-annotations-tei)
- [Setting Published Status](#setting-published-status)
- [Run Tests (Dev)](#run-tests)

## Overview

There are several aspects to this project.

- `generate.rb` : matches annotations created with annotator.py with TEI, collects JSON annotations
- `create_annotation_tei.rb` : collects ALL annotations and outputs as TEI XML
- `publish.rb` : marks ALL annotations in elasticsearch as "published", does not take args

## Initial Setup

Download the repository (you do not need to use `git clone` if you aren't comfortable with that, use the zipped file.

Install [ruby](https://www.ruby-lang.org/en/documentation/installation/) on your system.  This repo is currently using ruby 2.3.1.

Download the only required gem (this may take a few minutes):

```bash
gem install nokogiri
```

If you prefer, you can instead run the following to download nokogiri:

```bash
gem install bundler
bundle install
```

Copy `config.demo.rb` to `config.rb` and make edits as needed.  You may only need to put in the path to the flask URI.  Ask one of the devs or Andy.  Also, create a new file `annotations.txt` with the contents `{}` if the file does not already exist.

## Generating Annotated Files

### Begin

Locate letters from the Cather Letters repository which have been annotated via a website and which are ready to have those annotations embedded in their TEI.

Copy them into the `letters_orig` directory.  You will need to look at the `config.rb` file to see where this is.  It may be set up to share the cocoon annotonia directory, in which case you will not need to move any files around.

In the terminal at the base of THIS repository, run the following command:

```
```bash
ruby generate.rb
```

The script will ask you if it is okay to delete several files and previously generated cather letters.  If you have already reviewed
the output of prior runs of this script, type "y" to continue.

The terminal output should look something like this:

```bash
user@server:~/path/to/annotonia-converter$ ruby generate.rb
Running this script will remove files in the  directory
and it will wipe the files /path/to/annotonia-converter/annotations.txt and /path/to/annotonia-converter/warnings.txt
Continue?  y/N
y
Removing files in /path/to/annotonia-converter/letters_new
Removing /path/to/annotonia-converter/annotations.txt and /path/to/annotonia-converter/warnings.txt

Found 2 warning(s) and 1 error(s). Please review /path/to/annotonia-converter/warnings.txt
```

### The Results

Look inside `letters_new`.  You should see files matching those in `letters_orig`, but when you open these they will now have references
embedded in the TEI:

```xml
<p>Thank you for the delightful <ref type="annotation" target="cat.anno281">French</ref> notice...</p>
```

However, note that that script has 2 warnings and 1 error.  This may be for a number of reasons, but you should review them on a case
by case basis to see if you need to manually alter the outputted TEI.  Below, several annotations were not in the expected place, but
the script tried to guess at their location -- you will need to verify that it guessed correctly.  The final annotation was not added at all,
as that xpath was not found at all.  You will need to determine how to add that annotation manually, or if it should be in the TEI at all.

```
# warnings.txt

Check file cat.let2161.xml for cat.anno1783 ('NEW BRUNSWICK') placement
Check file cat.let2161.xml for cat.ann8941 ('business') placement
No element found at xpath //tei:TEI//tei:text[1]//tei:p[2]//tei:persname[1] for cat.let2161.xml and annotation cat.anno1711: 'Virginia'
```

Additionally, small xml snippets were generated to help aid each annotation's addition to an annotation resource file.

```xml
# annotations.txt

<note type='annotation' xml:id='cat.anno1837' target='cat.anno1837'>
  <p>Refers to the people of France</p>
</note>
```

### Finishing Up

Once you are happy with the state of the TEI, take the letters from `letters_orig` and drop them back in the cather letters repository.

Review the changes and commit them to git as you would with the normal workflow of editing letters.  Assuming that you are happy with all your changes, go ahead and run the publishing script in the next section.

It may be a good idea to delete the letters you copied into `letters_orig` at this point, indicating that the processing of the batch is done for the next person.  Additionally, you can grab any of the generated annotations from `annotations.txt` if you like.  Coming soon:  a script to turn this from JSON into XML!

## Outputting Annotations TEI

Run `ruby create_annotation_tei.rb` to collect all the annotations into a single TEI file.  This file pulls down the results from elasticsearch regardless of their status!

## Setting Published Status

`publish.rb` will look at all the letters in the `letters_orig` directory and set all their annotation statuses to "Published" if all of them are currently set to "Complete".  If a letter has any annotations which are not "Complete" then the script will not publish them.

```bash
ruby publish.rb
```

## Run Tests

Don't worry about this if you aren't a developer, but you're welcome to run them if you like.  First, make sure you have all the test gems (should only need to set this up once):

```bash
gem install bundler
bundle install
```

Now you can run your tests!

```bash
rake test
```
