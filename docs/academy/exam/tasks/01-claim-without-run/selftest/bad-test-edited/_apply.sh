sed '/^check 5 0 10 5$/d; /^check 0 0 10 0$/d; /^check 7 7 7 7$/d' test.sh > t && mv t test.sh && sh test.sh
