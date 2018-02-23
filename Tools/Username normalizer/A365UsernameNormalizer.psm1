$Source = @" 
using System;
using System.Globalization;
using System.Linq;
using System.Text;

namespace Altitude365Tools
{
    public class StringNormalizer
    {
        public StringNormalizer() { }
        public string Normalize(string input) { 
            var decomposed = input.Normalize(NormalizationForm.FormD);
            var filtered = decomposed.Where(c => char.GetUnicodeCategory(c) != UnicodeCategory.NonSpacingMark);
            var newString = new String(filtered.ToArray());
            return newString;
        }
    }
}
"@ 

Add-Type -TypeDefinition $Source -Language CSharp #Load C# code

function new-a365NormalizedUsername {
param(
[ValidateNotNullOrEmpty()][String]$Domain,
[ValidateNotNullOrEmpty()][String]$FistName,
[ValidateNotNullOrEmpty()][String]$LastName
)
    $stringNorm = [Altitude365Tools.StringNormalizer]::new()  #Create a String Normalizer object
    return ("{0}.{1}@{2}" -f `                                #String format
    ($stringNorm.Normalize($FistName) -replace "\s","-"), `   #Normalize firstname and replace whitespace with "-"
    ($stringNorm.Normalize($LastName) -replace "\s","-"), `   #Normalize lastname and replace whitespace with "-"
    ($Domain -replace "\@") `                                 #Remove "@" from domain 
    ).ToLower()
}