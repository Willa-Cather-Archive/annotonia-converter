# annotonia-converter
Alters Cather TEI letters with annotations from the annotonia

## Initial Setup

Download the repository (you do not need to use `git clone` if you aren't comfortable with that, use the zipped file.

Install [ruby](https://www.ruby-lang.org/en/documentation/installation/) on your system.  This repo is currently using ruby 2.2.0.

Download the only required gem (this may take a few minutes):

```
gem install nokogiri
```

Copy `config.demo.rb` to `config.rb` and make edits as needed.  You may only need to put in the path to the flask URI.  Ask one of the devs or Andy.

## Running the Script

### Begin

Locate letters from the Cather Letters repository which have been annotated via a website and which are ready to have those 
annotations embedded in their TEI.

Copy them into the `letters_orig` directory.  You may wish to remove any existing files from that directory before you begin.

In the terminal at the base of the repository, run this command:

```
ruby generate.rb
```

The script will ask you if it is okay to delete several files and previously generated cather letters.  If you have already reviewed
the output of prior runs of this script, type "y" to continue.

The terminal output should look something like this:

```
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

Review the changes and commit them to git as you would with the normal workflow of editing letters.

Add the new annotations to an annotations resource file, if you plan on using one.  It may be a good idea to delete the letters you 
copied into `letters_orig` at this point, indicating that the processing of the batch is done for the next person.

## Run Tests (For Developers)

### Setup

```
gem install bundler
bundle install
rake test
```
