# bust
Yet another directory buster.

This is a proof-of-concept directory buster written in bash using curl and wget that probably doesn't add anything new to the excellent existing directory busters out there.

---
  
# Usage
 
`bust.sh -w "<some wordlist|number|0number>" -u "<some url>" -v -c -d -t 10 -s <seperator> -x '<.ext .ens .ion .s>' -m '<METHOD>'`
  
## Parameters
 
-h				Help

-w wordlist|number|0number	Wordlist (=file) to use. If a number (not a file), then count until this number. If the number starts with 0, pad the number with leading zero's.

-u url			    URL. Whatever url. This is PREpended to the words (or numbers) from the wordlist (-w)

-s seperator		Seperator. Often this is /. Sometimes a blank is needed to let a counter append to the URL. See examples.

-x extensions		Extensions to check. Each word from wordlist has this extension appended. See examples.

-t threads			Number of checks to perform in parallel. Should be numerical and greater than 0.

-m method			  A HTTP-method can be specified. Usually GET, HEAD or POST.

-v              Verbose output. Also show responses other than 200 or 301/302.

-c				      Colorize output. Use fancy colors. It's 2021 you know.

-d				      Don't wait for the scan to complete and download those potential short lived files when found. I needed this.
 

# Examples
 
~/bin/bust.sh -w 09999 -x '.zip' -s '' -m HEAD -cvu http://10.31.73.11/backups/backup_2021111010

Append four zero padded digits up to 9999 after the URL and add .zip as extension. Use HEAD (instead of GET). Be verbose (showing 404s) and colorize the output.
 
