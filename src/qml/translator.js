.pragma library
// Translation helpers taken from MeeTranslate (same authors, MIT).
// Pure functions; MainPage.qml sends the requests through net (main.py).

// Google Translate languages (codes and names in the UI languages), from translate_a/l, 28.10.2026.
var data = {"source":["auto","ab","ace","ach","aa","af","sq","alz","am","ar","hy","as","av","awa","ay","az","ban","bal","bm","bci","ba","eu","btx","bts","bbc","be","bem","bn","bew","bho","bik","bs","br","bg","bua","yue","ca","ceb","ch","ce","ny","zh-CN","chk","cv","co","crh","crh-Latn","hr","cs","da","fa-AF","dv","din","doi","dov","nl","dyu","dz","en","eo","et","ee","fo","fj","tl","fi","fon","fr","fr-CA","fy","fur","ff","gaa","gl","ka","de","el","gn","gu","ht","cnh","ha","haw","iw","hil","hi","hmn","hu","hrx","iba","is","ig","ilo","id","iu-Latn","iu","ga","it","jam","ja","jw","kac","kl","kn","kr","pam","kk","kha","km","cgg","kg","rw","ktu","trp","kv","gom","ko","kri","ku","ckb","ky","lo","ltg","la","lv","lij","li","ln","lt","lmo","lg","luo","lb","mk","mad","mai","mak","mg","ms","ms-Arab","ml","mt","mam","gv","mi","mr","mh","mwr","mfe","chm","mni-Mtei","min","lus","mn","my","nhe","ndc-ZW","nr","new","ne","bm-Nkoo","no","nus","oc","or","om","os","pag","pap","ps","fa","pl","pt","pt-PT","pa","pa-Arab","qu","kek","rom","ro","rn","ru","se","sm","sg","sa","sat-Latn","sat","gd","nso","sr","st","crs","shn","sn","scn","szl","sd","si","sk","sl","so","es","su","sus","sw","ss","sv","ty","tg","ber-Latn","ber","ta","tt","te","tet","th","bo","ti","tiv","tpi","to","lua","ts","tn","tcy","tum","tr","tk","tyv","ak","udm","uk","ur","ug","uz","ve","vec","vi","war","cy","wo","xh","sah","yi","yo","yua","zap","zu"],"target":["ab","ace","ach","aa","af","sq","alz","am","ar","hy","as","av","awa","ay","az","ban","bal","bm","bci","ba","eu","btx","bts","bbc","be","bem","bn","bew","bho","bik","bs","br","bg","bua","yue","ca","ceb","ch","ce","ny","zh-CN","zh-TW","chk","cv","co","crh","crh-Latn","hr","cs","da","fa-AF","dv","din","doi","dov","nl","dyu","dz","en","eo","et","ee","fo","fj","tl","fi","fon","fr","fr-CA","fy","fur","ff","gaa","gl","ka","de","el","gn","gu","ht","cnh","ha","haw","iw","hil","hi","hmn","hu","hrx","iba","is","ig","ilo","id","iu-Latn","iu","ga","it","jam","ja","jw","kac","kl","kn","kr","pam","kk","kha","km","cgg","kg","rw","ktu","trp","kv","gom","ko","kri","ku","ckb","ky","lo","ltg","la","lv","lij","li","ln","lt","lmo","lg","luo","lb","mk","mad","mai","mak","mg","ms","ms-Arab","ml","mt","mam","gv","mi","mr","mh","mwr","mfe","chm","mni-Mtei","min","lus","mn","my","nhe","ndc-ZW","nr","new","ne","bm-Nkoo","no","nus","oc","or","om","os","pag","pap","ps","fa","pl","pt","pt-PT","pa","pa-Arab","qu","kek","rom","ro","rn","ru","se","sm","sg","sa","sat-Latn","sat","gd","nso","sr","st","crs","shn","sn","scn","szl","sd","si","sk","sl","so","es","su","sus","sw","ss","sv","ty","tg","ber-Latn","ber","ta","tt","te","tet","th","bo","ti","tiv","tpi","to","lua","ts","tn","tcy","tum","tr","tk","tyv","ak","udm","uk","ur","ug","uz","ve","vec","vi","war","cy","wo","xh","sah","yi","yo","yua","zap","zu"],"names":{"pl":{"aa":"afar","ab":"abchaski","ace":"aceh","ach":"aczoli","af":"afrikaans","ak":"twi","alz":"alur","am":"amharski","ar":"arabski","as":"asamski","auto":"Wykryj język","av":"awarski","awa":"awadhi","ay":"ajmara","az":"azerski","ba":"baszkirski","bal":"beludżi","ban":"balijski","bbc":"batak toba","bci":"baule","be":"białoruski","bem":"bemba","ber":"tamazight (tifinagh)","ber-Latn":"tamazight","bew":"betawi","bg":"bułgarski","bho":"bhodźpuri","bik":"bikolski","bm":"bambara","bm-Nkoo":"n'ko","bn":"bengalski","bo":"tybetański","br":"bretoński","bs":"bośniacki","bts":"batak simalungun","btx":"batak karo","bua":"buriacki","ca":"kataloński","ce":"czeczeński","ceb":"cebuański","cgg":"chiga","ch":"czamorro","chk":"chuuk","chm":"wschodniomaryjski","ckb":"kurdyjski (sorani)","cnh":"lai","co":"korsykański","crh":"krymsko-tatarski (cyrylica)","crh-Latn":"krymsko-tatarski (łaciński)","crs":"kreolski (Seszele)","cs":"czeski","cv":"czuwaski","cy":"walijski","da":"duński","de":"niemiecki","din":"dinka","doi":"dogri","dov":"dombe","dv":"dhivehi","dyu":"diula","dz":"dzongkha","ee":"ewe","el":"grecki","en":"angielski","eo":"esperanto","es":"hiszpański","et":"estoński","eu":"baskijski","fa":"perski","fa-AF":"dari","ff":"ful","fi":"fiński","fj":"fidżyjski","fo":"farerski","fon":"fon","fr":"francuski","fr-CA":"francuski (Kanada)","fur":"friulski","fy":"fryzyjski","ga":"irlandzki","gaa":"ga","gd":"szkocki gaelicki","gl":"galicyjski","gn":"guarani","gom":"konkani","gu":"gudżarati","gv":"manx","ha":"hausa","haw":"hawajski","hi":"hindi","hil":"hiligaynon","hmn":"hmong","hr":"chorwacki","hrx":"hunsrik","ht":"kreolski (Haiti)","hu":"węgierski","hy":"ormiański","iba":"iban","id":"indonezyjski","ig":"igbo","ilo":"ilokański","is":"islandzki","it":"włoski","iu":"inuktut (sylabariusz)","iu-Latn":"inuktut (łaciński)","iw":"hebrajski","ja":"japoński","jam":"jamajski","jw":"jawajski","ka":"gruziński","kac":"jingpo","kek":"kekczi","kg":"kikongo","kha":"khasi","kk":"kazachski","kl":"grenlandzki","km":"khmerski","kn":"kannada","ko":"koreański","kr":"kanuri","kri":"krio","ktu":"kituba","ku":"kurdyjski (kurmandżi)","kv":"komi","ky":"kirgiski","la":"łaciński","lb":"luksemburski","lg":"luganda","li":"limburski","lij":"liguryjski","lmo":"lombardzki","ln":"lingala","lo":"laotański","lt":"litewski","ltg":"łatgalski","lua":"cziluba","luo":"luo","lus":"mizo","lv":"łotewski","mad":"madurski","mai":"maithili","mak":"makasarski","mam":"mam","mfe":"kreolski (Mauritius)","mg":"malgaski","mh":"marszalski","mi":"maoryski","min":"minang","mk":"macedoński","ml":"malajalam","mn":"mongolski","mni-Mtei":"meiteilon (manipuri)","mr":"marathi","ms":"malajski","ms-Arab":"malajski (jawi)","mt":"maltański","mwr":"marwadi","my":"birmański","ndc-ZW":"ndau","ne":"nepalski","new":"newarski (newari)","nhe":"nahuatl (wschodni huasteca)","nl":"niderlandzki","no":"norweski","nr":"ndebele (południowy)","nso":"sepedi","nus":"nuer","ny":"cziczewa","oc":"oksytański","om":"oromo","or":"odia (orija)","os":"osetyjski","pa":"pendżabski (gurmukhi)","pa-Arab":"pendżabski (szachmukhi)","pag":"pangasinan","pam":"pampango","pap":"papiamento","pl":"polski","ps":"paszto","pt":"portugalski (Brazylia)","pt-PT":"portugalski (Portugalia)","qu":"keczua","rn":"rundi","ro":"rumuński","rom":"romski","ru":"rosyjski","rw":"kinyarwanda","sa":"sanskryt","sah":"jakucki","sat":"santali (ol ciki)","sat-Latn":"santali (łaciński)","scn":"sycylijski","sd":"sindhi","se":"lapoński (północny)","sg":"sango","shn":"szan","si":"syngaleski","sk":"słowacki","sl":"słoweński","sm":"samoański","sn":"shona","so":"somalijski","sq":"albański","sr":"serbski","ss":"suazi","st":"sesotho","su":"sundajski","sus":"susu","sv":"szwedzki","sw":"suahili","szl":"śląski","ta":"tamilski","tcy":"tulu","te":"telugu","tet":"tetum","tg":"tadżycki","th":"tajski","ti":"tigrinia","tiv":"tiw","tk":"turkmeński","tl":"filipiński","tn":"tswana","to":"tonga","tpi":"tok pisin","tr":"turecki","trp":"kokborok","ts":"tsonga","tt":"tatarski","tum":"tumbuka","ty":"tahitański","tyv":"tuwiński","udm":"udmurcki","ug":"ujgurski","uk":"ukraiński","ur":"urdu","uz":"uzbecki","ve":"venda","vec":"wenecki","vi":"wietnamski","war":"warajski","wo":"wolof","xh":"xhosa","yi":"jidysz","yo":"joruba","yua":"maya","yue":"kantoński","zap":"zapotecki","zh-CN":"chiński","zh-TW":"chiński (tradycyjny)","zu":"zulu"},"en":{"aa":"Afar","ab":"Abkhaz","ace":"Acehnese","ach":"Acholi","af":"Afrikaans","ak":"Twi","alz":"Alur","am":"Amharic","ar":"Arabic","as":"Assamese","auto":"Detect language","av":"Avar","awa":"Awadhi","ay":"Aymara","az":"Azerbaijani","ba":"Bashkir","bal":"Baluchi","ban":"Balinese","bbc":"Batak Toba","bci":"Baoulé","be":"Belarusian","bem":"Bemba","ber":"Tamazight (Tifinagh)","ber-Latn":"Tamazight","bew":"Betawi","bg":"Bulgarian","bho":"Bhojpuri","bik":"Bikol","bm":"Bambara","bm-Nkoo":"NKo","bn":"Bengali","bo":"Tibetan","br":"Breton","bs":"Bosnian","bts":"Batak Simalungun","btx":"Batak Karo","bua":"Buryat","ca":"Catalan","ce":"Chechen","ceb":"Cebuano","cgg":"Kiga","ch":"Chamorro","chk":"Chuukese","chm":"Meadow Mari","ckb":"Kurdish (Sorani)","cnh":"Hakha Chin","co":"Corsican","crh":"Crimean Tatar (Cyrillic)","crh-Latn":"Crimean Tatar (Latin)","crs":"Seychellois Creole","cs":"Czech","cv":"Chuvash","cy":"Welsh","da":"Danish","de":"German","din":"Dinka","doi":"Dogri","dov":"Dombe","dv":"Dhivehi","dyu":"Dyula","dz":"Dzongkha","ee":"Ewe","el":"Greek","en":"English","eo":"Esperanto","es":"Spanish","et":"Estonian","eu":"Basque","fa":"Persian","fa-AF":"Dari","ff":"Fulani","fi":"Finnish","fj":"Fijian","fo":"Faroese","fon":"Fon","fr":"French","fr-CA":"French (Canada)","fur":"Friulian","fy":"Frisian","ga":"Irish","gaa":"Ga","gd":"Scots Gaelic","gl":"Galician","gn":"Guarani","gom":"Konkani","gu":"Gujarati","gv":"Manx","ha":"Hausa","haw":"Hawaiian","hi":"Hindi","hil":"Hiligaynon","hmn":"Hmong","hr":"Croatian","hrx":"Hunsrik","ht":"Haitian Creole","hu":"Hungarian","hy":"Armenian","iba":"Iban","id":"Indonesian","ig":"Igbo","ilo":"Ilocano","is":"Icelandic","it":"Italian","iu":"Inuktut (Syllabics)","iu-Latn":"Inuktut (Latin)","iw":"Hebrew","ja":"Japanese","jam":"Jamaican Patois","jw":"Javanese","ka":"Georgian","kac":"Jingpo","kek":"Qʼeqchiʼ","kg":"Kikongo","kha":"Khasi","kk":"Kazakh","kl":"Kalaallisut","km":"Khmer","kn":"Kannada","ko":"Korean","kr":"Kanuri","kri":"Krio","ktu":"Kituba","ku":"Kurdish (Kurmanji)","kv":"Komi","ky":"Kyrgyz","la":"Latin","lb":"Luxembourgish","lg":"Luganda","li":"Limburgish","lij":"Ligurian","lmo":"Lombard","ln":"Lingala","lo":"Lao","lt":"Lithuanian","ltg":"Latgalian","lua":"Tshiluba","luo":"Luo","lus":"Mizo","lv":"Latvian","mad":"Madurese","mai":"Maithili","mak":"Makassar","mam":"Mam","mfe":"Mauritian Creole","mg":"Malagasy","mh":"Marshallese","mi":"Maori","min":"Minang","mk":"Macedonian","ml":"Malayalam","mn":"Mongolian","mni-Mtei":"Meiteilon (Manipuri)","mr":"Marathi","ms":"Malay","ms-Arab":"Malay (Jawi)","mt":"Maltese","mwr":"Marwadi","my":"Myanmar (Burmese)","ndc-ZW":"Ndau","ne":"Nepali","new":"Nepalbhasa (Newari)","nhe":"Nahuatl (Eastern Huasteca)","nl":"Dutch","no":"Norwegian","nr":"Ndebele (South)","nso":"Sepedi","nus":"Nuer","ny":"Chichewa","oc":"Occitan","om":"Oromo","or":"Odia (Oriya)","os":"Ossetian","pa":"Punjabi (Gurmukhi)","pa-Arab":"Punjabi (Shahmukhi)","pag":"Pangasinan","pam":"Kapampangan","pap":"Papiamento","pl":"Polish","ps":"Pashto","pt":"Portuguese (Brazil)","pt-PT":"Portuguese (Portugal)","qu":"Quechua","rn":"Rundi","ro":"Romanian","rom":"Romani","ru":"Russian","rw":"Kinyarwanda","sa":"Sanskrit","sah":"Yakut","sat":"Santali (Ol Chiki)","sat-Latn":"Santali (Latin)","scn":"Sicilian","sd":"Sindhi","se":"Sami (North)","sg":"Sango","shn":"Shan","si":"Sinhala","sk":"Slovak","sl":"Slovenian","sm":"Samoan","sn":"Shona","so":"Somali","sq":"Albanian","sr":"Serbian","ss":"Swati","st":"Sesotho","su":"Sundanese","sus":"Susu","sv":"Swedish","sw":"Swahili","szl":"Silesian","ta":"Tamil","tcy":"Tulu","te":"Telugu","tet":"Tetum","tg":"Tajik","th":"Thai","ti":"Tigrinya","tiv":"Tiv","tk":"Turkmen","tl":"Filipino","tn":"Tswana","to":"Tongan","tpi":"Tok Pisin","tr":"Turkish","trp":"Kokborok","ts":"Tsonga","tt":"Tatar","tum":"Tumbuka","ty":"Tahitian","tyv":"Tuvan","udm":"Udmurt","ug":"Uyghur","uk":"Ukrainian","ur":"Urdu","uz":"Uzbek","ve":"Venda","vec":"Venetian","vi":"Vietnamese","war":"Waray","wo":"Wolof","xh":"Xhosa","yi":"Yiddish","yo":"Yoruba","yua":"Yucatec Maya","yue":"Cantonese","zap":"Zapotec","zh-CN":"Chinese","zh-TW":"Chinese (Traditional)","zu":"Zulu"},"de":{"aa":"Afar","ab":"Abchasisch","ace":"Aceh","ach":"Acholi","af":"Afrikaans","ak":"Twi","alz":"Alur","am":"Amharisch","ar":"Arabisch","as":"Assamesisch","auto":"Sprache erkennen","av":"Awarisch","awa":"Awadhi","ay":"Aymara","az":"Aserbaidschanisch","ba":"Baschkirisch","bal":"Belutschi","ban":"Balinesisch","bbc":"Toba-Batak","bci":"Baoulé","be":"Belarussisch","bem":"Bemba","ber":"Tamazight (Tifinagh)","ber-Latn":"Tamazight","bew":"Betawi","bg":"Bulgarisch","bho":"Bhojpuri","bik":"Bikol","bm":"Bambara","bm-Nkoo":"N’Ko","bn":"Bengalisch","bo":"Tibetisch","br":"Bretonisch","bs":"Bosnisch","bts":"Simalungun-Batak","btx":"Karo-Batak","bua":"Burjatisch","ca":"Katalanisch","ce":"Tschetschenisch","ceb":"Cebuano","cgg":"Kiga","ch":"Chamorro","chk":"Chuukesisch","chm":"Wiesenmari","ckb":"Kurdisch (Sorani)","cnh":"Hakha Chin","co":"Korsisch","crh":"Krimtatarisch (Kyrillisch)","crh-Latn":"Krimtatarisch (lat. Alphabet)","crs":"Seychellenkreol","cs":"Tschechisch","cv":"Tschuwaschisch","cy":"Walisisch","da":"Dänisch","de":"Deutsch","din":"Dinka","doi":"Dogri","dov":"Dombe","dv":"Dhivehi","dyu":"Dioula","dz":"Dzongkha","ee":"Ewe","el":"Griechisch","en":"Englisch","eo":"Esperanto","es":"Spanisch","et":"Estnisch","eu":"Baskisch","fa":"Persisch","fa-AF":"Dari","ff":"Fulfulde","fi":"Finnisch","fj":"Fidschianisch","fo":"Färöisch","fon":"Fon","fr":"Französisch","fr-CA":"Französisch (Kanada)","fur":"Furlanisch","fy":"Friesisch","ga":"Irisch","gaa":"Ga","gd":"Schottisch-Gälisch","gl":"Galizisch","gn":"Guarani","gom":"Konkani","gu":"Gujarati","gv":"Manx","ha":"Hausa","haw":"Hawaiisch","hi":"Hindi","hil":"Hiligaynon","hmn":"Hmong","hr":"Kroatisch","hrx":"Riograndenser Hunsrückisch","ht":"Haitianisch","hu":"Ungarisch","hy":"Armenisch","iba":"Iban","id":"Indonesisch","ig":"Igbo","ilo":"Ilokano","is":"Isländisch","it":"Italienisch","iu":"Inuktitut (Silbenschrift)","iu-Latn":"Inuktut (lat. Alphabet)","iw":"Hebräisch","ja":"Japanisch","jam":"Jamaikanisches Kreolisch","jw":"Javanisch","ka":"Georgisch","kac":"Jingpo","kek":"Kekchí","kg":"Kikongo","kha":"Khasi","kk":"Kasachisch","kl":"Kalaallisut","km":"Khmer","kn":"Kannada","ko":"Koreanisch","kr":"Kanuri","kri":"Krio","ktu":"Kituba","ku":"Kurdisch (Kurmandschi)","kv":"Komi","ky":"Kirgisisch","la":"Latein","lb":"Luxemburgisch","lg":"Luganda","li":"Limburgisch","lij":"Ligurisch","lmo":"Lombardisch","ln":"Lingala","lo":"Lao","lt":"Litauisch","ltg":"Lettgallisch","lua":"Tschiluba","luo":"Luo","lus":"Mizo","lv":"Lettisch","mad":"Maduresisch","mai":"Maithili","mak":"Makassar","mam":"Mam","mfe":"Kreolisch (Mauritius)","mg":"Malagasy","mh":"Marshallesisch","mi":"Maori","min":"Minangkabauisch","mk":"Mazedonisch","ml":"Malayalam","mn":"Mongolisch","mni-Mtei":"Meitei (Manipurisch)","mr":"Marathi","ms":"Malaysisch","ms-Arab":"Malaiisch (Jawi)","mt":"Maltesisch","mwr":"Marwari","my":"Myanmar (Birmanisch)","ndc-ZW":"Ndau","ne":"Nepalesisch","new":"Nepal Bhasa (Newari)","nhe":"Nahuatl (Ost-Huasteca)","nl":"Niederländisch","no":"Norwegisch","nr":"Ndebele (Süd)","nso":"Nord-Sotho","nus":"Nuer","ny":"Chichewa","oc":"Okzitanisch","om":"Oromo","or":"Odia (Oriya)","os":"Ossetisch","pa":"Panjabi (Gurmukhi)","pa-Arab":"Panjabi (Shahmukhi)","pag":"Pangasinensisch","pam":"Kapampangan","pap":"Papiamentu","pl":"Polnisch","ps":"Paschtu","pt":"Portugiesisch (Brasilien)","pt-PT":"Portugiesisch (Portugal)","qu":"Quechua","rn":"Kirundi","ro":"Rumänisch","rom":"Romani","ru":"Russisch","rw":"Kinyarwanda","sa":"Sanskrit","sah":"Jakutisch","sat":"Santali (Ol Chiki)","sat-Latn":"Santali (lat. Alphabet)","scn":"Sizilianisch","sd":"Sindhi","se":"Samisch (Nord)","sg":"Sango","shn":"Shan","si":"Singhalesisch","sk":"Slowakisch","sl":"Slowenisch","sm":"Samoanisch","sn":"Shona","so":"Somali","sq":"Albanisch","sr":"Serbisch","ss":"Siswati","st":"Sesotho","su":"Sundanesisch","sus":"Susu","sv":"Schwedisch","sw":"Swahili","szl":"Schlesisch","ta":"Tamil","tcy":"Tulu","te":"Telugu","tet":"Tetum","tg":"Tadschikisch","th":"Thailändisch","ti":"Tigrinya","tiv":"Tiv","tk":"Turkmenisch","tl":"Filipino","tn":"Setswana","to":"Tongaisch","tpi":"Tok Pisin","tr":"Türkisch","trp":"Kokborok","ts":"Tsonga","tt":"Tatarisch","tum":"Tumbuka","ty":"Tahitianisch","tyv":"Tuwinisch","udm":"Udmurtisch","ug":"Uigurisch","uk":"Ukrainisch","ur":"Urdu","uz":"Usbekisch","ve":"Venda","vec":"Venetisch","vi":"Vietnamesisch","war":"Waray-Waray","wo":"Wolof","xh":"Xhosa","yi":"Jiddisch","yo":"Yoruba","yua":"Mayathan","yue":"Kantonesisch","zap":"Zapotekisch","zh-CN":"Chinesisch","zh-TW":"Chinesisch (traditionell)","zu":"Zulu"},"es":{"aa":"afar","ab":"abjasio","ace":"achenés","ach":"acholi","af":"afrikáans","ak":"twi","alz":"alur","am":"amhárico","ar":"árabe","as":"asamés","auto":"Detectar idioma","av":"avar","awa":"avadhi","ay":"aimara","az":"azerí","ba":"baskir","bal":"baluchí","ban":"balinés","bbc":"batak toba","bci":"baoulé","be":"bielorruso","bem":"bemba","ber":"tamazight (tifinag)","ber-Latn":"tamazight","bew":"betawi","bg":"búlgaro","bho":"bhoyapurí","bik":"bikol","bm":"bambara","bm-Nkoo":"n'ko","bn":"bengalí","bo":"tibetano","br":"bretón","bs":"bosnio","bts":"batak simalungun","btx":"batak karo","bua":"buriato","ca":"catalán","ce":"checheno","ceb":"cebuano","cgg":"kiga","ch":"chamorro","chk":"trukés","chm":"marí de las praderas","ckb":"kurdo (sorani)","cnh":"hakha chin","co":"corso","crh":"tártaro de Crimea (cirílico)","crh-Latn":"tártaro de Crimea (latino)","crs":"criollo seychellense","cs":"checo","cv":"chuvasio","cy":"galés","da":"danés","de":"alemán","din":"dinka","doi":"dogri","dov":"ndombe","dv":"divehi","dyu":"diula","dz":"dzongkha","ee":"ewé","el":"griego","en":"inglés","eo":"esperanto","es":"español","et":"estonio","eu":"euskera","fa":"persa","fa-AF":"darí","ff":"fulani","fi":"finlandés","fj":"fiyiano","fo":"feroés","fon":"fon","fr":"francés","fr-CA":"francés (Canadá)","fur":"friulano","fy":"frisio","ga":"irlandés","gaa":"ga","gd":"gaélico escocés","gl":"gallego","gn":"guaraní","gom":"konkaní","gu":"gujarati","gv":"manés","ha":"hausa","haw":"hawaiano","hi":"hindi","hil":"hiligaynon","hmn":"hmong","hr":"croata","hrx":"hunsrik","ht":"criollo haitiano","hu":"húngaro","hy":"armenio","iba":"iban","id":"indonesio","ig":"igbo","ilo":"ilocano","is":"islandés","it":"italiano","iu":"inuktut (silabario)","iu-Latn":"inuktut (latino)","iw":"hebreo","ja":"japonés","jam":"patois jamaiquino","jw":"javanés","ka":"georgiano","kac":"jingpo","kek":"quekchí","kg":"kikongo","kha":"khasi","kk":"kazajo","kl":"kalaallisut","km":"camboyano","kn":"canarés","ko":"coreano","kr":"kanuri","kri":"krio","ktu":"kituba","ku":"kurdo (kurmanyi)","kv":"komi","ky":"kirguís","la":"latín","lb":"luxemburgués","lg":"luganda","li":"limburgués","lij":"ligur","lmo":"lombardo","ln":"lingala","lo":"lao","lt":"lituano","ltg":"latgaliano","lua":"chiluba","luo":"luo","lus":"mizo","lv":"letón","mad":"madurés","mai":"maithili","mak":"makassar","mam":"mam","mfe":"criollo mauriciano","mg":"malgache","mh":"marshalés","mi":"maorí","min":"minangkabau","mk":"macedonio","ml":"malayalam","mn":"mongol","mni-Mtei":"meiteilon (manipurí)","mr":"maratí","ms":"malayo","ms-Arab":"malayo (jawi)","mt":"maltés","mwr":"marwari","my":"birmano","ndc-ZW":"ndau","ne":"nepalí","new":"nepalbhasa (newarí)","nhe":"náhuatl (Huasteca oriental)","nl":"neerlandés","no":"noruego","nr":"ndebele meridional","nso":"sepedi","nus":"nuer","ny":"chichewa","oc":"occitano","om":"oromo","or":"odia (oriya)","os":"osético","pa":"panyabí (gurmukhi)","pa-Arab":"panyabí (shahmukhi)","pag":"pangasinán","pam":"pampango","pap":"papiamento","pl":"polaco","ps":"pastún","pt":"portugués (Brasil)","pt-PT":"portugués (Portugal)","qu":"quechua","rn":"kirundi","ro":"rumano","rom":"romaní","ru":"ruso","rw":"kinyarwanda","sa":"sánscrito","sah":"yakuto","sat":"santalí (ol chiki)","sat-Latn":"santalí (latino)","scn":"siciliano","sd":"sindhi","se":"sami septentrional","sg":"sango","shn":"shan","si":"cingalés","sk":"eslovaco","sl":"esloveno","sm":"samoano","sn":"shona","so":"somalí","sq":"albanés","sr":"serbio","ss":"suazi","st":"sesoto","su":"sundanés","sus":"susu","sv":"sueco","sw":"suajili","szl":"silesio","ta":"tamil","tcy":"tulu","te":"telugu","tet":"tetun","tg":"tayiko","th":"tailandés","ti":"tigrinya","tiv":"tiv","tk":"turkmeno","tl":"filipino","tn":"setsuana","to":"tongano","tpi":"tok pisin","tr":"turco","trp":"kokborok","ts":"tsonga","tt":"tártaro","tum":"tumbuka","ty":"tahitiano","tyv":"tuviniano","udm":"udmurto","ug":"uigur","uk":"ucraniano","ur":"urdu","uz":"uzbeco","ve":"venda","vec":"véneto","vi":"vietnamita","war":"samareño","wo":"wólof","xh":"xhosa","yi":"yidis","yo":"yoruba","yua":"maya yucateco","yue":"cantonés","zap":"zapoteco","zh-CN":"Chino","zh-TW":"chino (tradicional)","zu":"zulú"},"it":{"aa":"Afar","ab":"Abcaso","ace":"Accinese","ach":"Acioli","af":"Afrikaans","ak":"Ci","alz":"Alur","am":"Amarico","ar":"Arabo","as":"Assamese","auto":"Rileva lingua","av":"Avaro","awa":"Awadhi","ay":"Aymara","az":"Azero","ba":"Bashkir","bal":"Beluci","ban":"Balinese","bbc":"Batak toba","bci":"Baulé","be":"Bielorusso","bem":"Wemba","ber":"Tamazight (Tifinagh)","ber-Latn":"Tamazight","bew":"Betawi","bg":"Bulgaro","bho":"Bhojpuri","bik":"Bicol","bm":"Bambara","bm-Nkoo":"N'Ko","bn":"Bengalese","bo":"Tibetano","br":"Bretone","bs":"Bosniaco","bts":"Batak simalungun","btx":"Batak karo","bua":"Buriat","ca":"Catalano","ce":"Ceceno","ceb":"Cebuano","cgg":"Chiga","ch":"Chamorro","chk":"Chuukese","chm":"Mari Meadow","ckb":"Curdo (Sorani)","cnh":"Hakha Chin","co":"Corso","crh":"Tataro di Crimea (cirillico)","crh-Latn":"Tataro di Crimea (latino)","crs":"Creolo delle Seychelles","cs":"Ceco","cv":"Ciuvascio","cy":"Gallese","da":"Danese","de":"Tedesco","din":"Dinka","doi":"Dogri","dov":"Dombe","dv":"Dhivehi","dyu":"Diula","dz":"Dzongkha","ee":"Ewe","el":"Greco","en":"Inglese","eo":"Esperanto","es":"Spagnolo","et":"Estone","eu":"Basco","fa":"Persiano","fa-AF":"Dari","ff":"Fulah","fi":"Finlandese","fj":"Figiano","fo":"Faroese","fon":"Fon","fr":"Francese","fr-CA":"Francese (Canada)","fur":"Friulano","fy":"Frisone","ga":"Irlandese","gaa":"Ga","gd":"Gaelico scozzese","gl":"Galiziano","gn":"Guaraní","gom":"Konkani","gu":"Gujarati","gv":"Manx","ha":"Hausa","haw":"Hawaiano","hi":"Hindi","hil":"Ilongo","hmn":"Hmong","hr":"Croato","hrx":"Hunsrik","ht":"Creolo haitiano","hu":"Ungherese","hy":"Armeno","iba":"Iban","id":"Indonesiano","ig":"Igbo","ilo":"Ilocano","is":"Islandese","it":"Italiano","iu":"Inuktut (sillabico)","iu-Latn":"Inuktut (latino)","iw":"Ebraico","ja":"Giapponese","jam":"Patois giamaicano","jw":"Giavanese","ka":"Georgiano","kac":"Jingpo","kek":"Q'eqchi'","kg":"Kongo","kha":"Khasi","kk":"Kazako","kl":"Kalaallisut","km":"Khmer","kn":"Kannada","ko":"Coreano","kr":"Kanuri","kri":"Krio","ktu":"Kituba","ku":"Curdo (Kurmanji)","kv":"Komi","ky":"Chirghiso","la":"Latino","lb":"Lussemburghese","lg":"Luganda","li":"Limburghese","lij":"Ligure","lmo":"Lombardo","ln":"Lingala","lo":"Lao","lt":"Lituano","ltg":"Letgallo","lua":"Tshiluba","luo":"Luo","lus":"Mizo","lv":"Lettone","mad":"Madurese","mai":"Maithili","mak":"Makasar","mam":"Mam","mfe":"Creolo mauriziano","mg":"Malgascio","mh":"Marshallese","mi":"Maori","min":"Menangkabau","mk":"Macedone","ml":"Malayalam","mn":"Mongolo","mni-Mtei":"Meiteilon (Manipuri)","mr":"Marathi","ms":"Malese","ms-Arab":"Malese (Jawi)","mt":"Maltese","mwr":"Marwari","my":"Birmano","ndc-ZW":"Ndau","ne":"Nepalese","new":"Nepalbhasa (newari)","nhe":"Nahuatl (Huasteca orientale)","nl":"Olandese","no":"Norvegese","nr":"Ndebele del sud","nso":"Sepedi","nus":"Nuer","ny":"Chichewa","oc":"Occitano","om":"Oromo","or":"Odia (Oriya)","os":"Osseto","pa":"Punjabi (Gurmukhi)","pa-Arab":"Punjabi (Shahmukhi)","pag":"Pangasinan","pam":"Kapampangan","pap":"Papiamento","pl":"Polacco","ps":"Pashto","pt":"Portoghese (Brasile)","pt-PT":"Portoghese (Portogallo)","qu":"Quechua","rn":"Rundi","ro":"Rumeno","rom":"Romanì","ru":"Russo","rw":"Kinyarwanda","sa":"Sanscrito","sah":"Yakut","sat":"Santali (Ol Chiki)","sat-Latn":"Santali (latino)","scn":"Siciliano","sd":"Sindhi","se":"Sami del nord","sg":"Sango","shn":"Shan","si":"Singalese","sk":"Slovacco","sl":"Sloveno","sm":"Samoano","sn":"Shona","so":"Somalo","sq":"Albanese","sr":"Serbo","ss":"Swati","st":"Sesotho","su":"Sundanese","sus":"Susu","sv":"Svedese","sw":"Swahili","szl":"Slesiano","ta":"Tamil","tcy":"Tulu","te":"Telugu","tet":"Tetum","tg":"Tagico","th":"Thai","ti":"Tigrino","tiv":"Tiv","tk":"Turkmeno","tl":"Filippino","tn":"Tswana","to":"Tongano","tpi":"Tok pisin","tr":"Turco","trp":"Kokborok","ts":"Tsonga","tt":"Tataro","tum":"Tumbuka","ty":"Taitiano","tyv":"Tuvinian","udm":"Udmurt","ug":"Uiguro","uk":"Ucraino","ur":"Urdu","uz":"Uzbeco","ve":"Venda","vec":"Veneziano","vi":"Vietnamita","war":"Waray","wo":"Wolof","xh":"Xhosa","yi":"Yiddish","yo":"Yoruba","yua":"Maya yucateco","yue":"Cantonese","zap":"Zapotec","zh-CN":"Cinese","zh-TW":"Cinese (tradizionale)","zu":"Zulu"},"fr":{"aa":"Afar","ab":"Abkhaze","ace":"Aceh","ach":"Acholi","af":"Afrikaans","ak":"Twi","alz":"Alur","am":"Amharique","ar":"Arabe","as":"Assamais","auto":"Détecter la langue","av":"Avar","awa":"Awadhi","ay":"Aymara","az":"Azéri","ba":"Bachkir","bal":"Baloutchi","ban":"Balinais","bbc":"Batak Toba","bci":"Baoulé","be":"Biélorusse","bem":"Bemba","ber":"Tamazight (Tifinagh)","ber-Latn":"Tamazight","bew":"Betawi","bg":"Bulgare","bho":"Bhodjpouri","bik":"Bicol","bm":"Bambara","bm-Nkoo":"NKo","bn":"Bengali","bo":"Tibétain","br":"Breton","bs":"Bosniaque","bts":"Batak Simalungun","btx":"Batak Karo","bua":"Bouriate","ca":"Catalan","ce":"Tchétchène","ceb":"Cebuano","cgg":"Kiga","ch":"Chamorro","chk":"Chuuk","chm":"Mari des prairies","ckb":"Kurde (Sorani)","cnh":"Hakha Chin","co":"Corse","crh":"Tatar de Crimée (cyrillique)","crh-Latn":"Tatar de Crimée (latin)","crs":"Créole seychellois","cs":"Tchèque","cv":"Tchouvache","cy":"Gallois","da":"Danois","de":"Allemand","din":"Dinka","doi":"Dogri","dov":"Dombe","dv":"Divéhi","dyu":"Dioula","dz":"Dzongkha","ee":"Ewe","el":"Grec","en":"Anglais","eo":"Espéranto","es":"Espagnol","et":"Estonien","eu":"Basque","fa":"Persan","fa-AF":"Dari","ff":"Peul","fi":"Finnois","fj":"Fidjien","fo":"Féroïen","fon":"Fon","fr":"Français","fr-CA":"Français (Canada)","fur":"Frioulan","fy":"Frison","ga":"Irlandais","gaa":"Ga","gd":"Gaélique (Écosse)","gl":"Galicien","gn":"Guarani","gom":"Konkani","gu":"Gujarati","gv":"Manx","ha":"Haoussa","haw":"Hawaïen","hi":"Hindi","hil":"Hiligaïnon","hmn":"Hmong","hr":"Croate","hrx":"Hunsrik","ht":"Créole haïtien","hu":"Hongrois","hy":"Arménien","iba":"Iban","id":"Indonésien","ig":"Igbo","ilo":"Ilocano","is":"Islandais","it":"Italien","iu":"Inuktut (syllabique)","iu-Latn":"Inuktut (latin)","iw":"Hébreu","ja":"Japonais","jam":"Patois jamaïcain","jw":"Javanais","ka":"Géorgien","kac":"Jingpo","kek":"Q'eqchi'","kg":"Kikongo","kha":"Khasi","kk":"Kazakh","kl":"Kalaallisut","km":"Khmer","kn":"Kannada","ko":"Coréen","kr":"Kanuri","kri":"Krio","ktu":"Kituba","ku":"Kurde (Kurmandji)","kv":"Komi","ky":"Kirghiz","la":"Latin","lb":"Luxembourgeois","lg":"Luganda","li":"Limbourgeois","lij":"Ligure","lmo":"Lombard","ln":"Lingala","lo":"Laotien","lt":"Lituanien","ltg":"Latgalien","lua":"Tshiluba","luo":"Luo","lus":"Mizo","lv":"Letton","mad":"Madurais","mai":"Maïthili","mak":"Macassar","mam":"Mam","mfe":"Créole mauricien","mg":"Malgache","mh":"Marshallais","mi":"Maori","min":"Minangkabau","mk":"Macédonien","ml":"Malayalam","mn":"Mongol","mni-Mtei":"Meitei (Manipuri)","mr":"Marathi","ms":"Malaisien","ms-Arab":"Malais (Jawi)","mt":"Maltais","mwr":"Marwari","my":"Myanmar (Birman)","ndc-ZW":"Ndau","ne":"Népalais","new":"Nepalbhasa (Newari)","nhe":"Nahuatl (Huasteca oriental)","nl":"Néerlandais","no":"Norvégien","nr":"Ndébélé (Sud)","nso":"Sepedi","nus":"Nuer","ny":"Chichewa","oc":"Occitan","om":"Oromo","or":"Odia (Oriya)","os":"Ossète","pa":"Panjabi (Gurmukhi)","pa-Arab":"Panjabi (Shahmukhi)","pag":"Pangasinan","pam":"Pampangan","pap":"Papiamento","pl":"Polonais","ps":"Pachtô","pt":"Portugais (Brésil)","pt-PT":"Portugais (Portugal)","qu":"Quechua","rn":"Roundi","ro":"Roumain","rom":"Romani","ru":"Russe","rw":"Kinyarwanda","sa":"Sanskrit","sah":"Yakoute","sat":"Santali (ol chiki)","sat-Latn":"Santali (latin)","scn":"Sicilien","sd":"Sindhî","se":"Same (Nord)","sg":"Sango","shn":"Shan","si":"Cinghalais","sk":"Slovaque","sl":"Slovène","sm":"Samoan","sn":"Shona","so":"Somali","sq":"Albanais","sr":"Serbe","ss":"Swati","st":"Sesotho","su":"Soundanais","sus":"Soussou","sv":"Suédois","sw":"Swahili","szl":"Silésien","ta":"Tamoul","tcy":"Toulou","te":"Telugu","tet":"Tétoum","tg":"Tadjik","th":"Thaï","ti":"Tigrigna","tiv":"Tiv","tk":"Turkmène","tl":"Philippin","tn":"Tswana","to":"Tongien","tpi":"Tok pisin","tr":"Turc","trp":"Kok Borok","ts":"Tsonga","tt":"Tatar","tum":"Tumbuka","ty":"Tahitien","tyv":"Touvain","udm":"Oudmourte","ug":"Ouïgour","uk":"Ukrainien","ur":"Urdu","uz":"Ouzbek","ve":"Venda","vec":"Vénitien","vi":"Vietnamien","war":"Waray-waray","wo":"Wolof","xh":"Xhosa","yi":"Yiddish","yo":"Yoruba","yua":"Maya yucatèque","yue":"Cantonais","zap":"Zapotèque","zh-CN":"Chinois","zh-TW":"Chinois (traditionnel)","zu":"Zoulou"}}};

// WikDict offline dictionaries: languages (WikDict codes) and the matching
// Google codes (used for names and for switching between services).
var WIKDICT = ["bg", "ca", "cs", "da", "de", "el", "en", "es", "fi", "fr", "ga", "id", "it",
               "ja", "ku", "la", "lt", "mg", "nl", "no", "pl", "pt", "ru", "sv", "tr", "zh"];
var WIKDICT_TO_GOOGLE = { "zh": "zh-CN" };

function googleCode(wikdict)
{
    return WIKDICT_TO_GOOGLE[wikdict] || wikdict;
}

function wikdictCode(google)
{
    for (var k in WIKDICT_TO_GOOGLE)
        if (WIKDICT_TO_GOOGLE[k] === google)
            return k;
    return WIKDICT.indexOf(google) >= 0 ? google : "";
}

function languageName(uiLang, code)
{
    var names = data.names[uiLang] || data.names["en"];
    return names[code] || data.names["en"][code] || code;
}

// list of {code, name} for a picker; service: google, mymemory, offline
function languages(uiLang, service, source)
{
    var codes;
    if (service === "offline") {
        codes = [];
        for (var i = 0; i < WIKDICT.length; ++i)
            codes.push(googleCode(WIKDICT[i]));
    } else {
        codes = source ? data.source : data.target;
    }
    var out = [];
    for (var j = 0; j < codes.length; ++j) {
        if (codes[j] === "auto" && (!source || service === "offline"))
            continue;
        out.push({ "code": codes[j], "name": languageName(uiLang, codes[j]) });
    }
    out.sort(function(a, b) {
        if (a.code === "auto") return -1;
        if (b.code === "auto") return 1;
        return a.name.localeCompare(b.name);
    });
    return out;
}

// ---- Google Translate (translate.googleapis.com, client=gtx) ----

function googleUrl(secure, from, to, uiLang)
{
    return (secure ? "https" : "http") + "://translate.googleapis.com/translate_a/single"
            + "?client=gtx&ie=UTF-8&oe=UTF-8&dt=t&dt=bd&dt=rm"
            + "&sl=" + encodeURIComponent(from) + "&tl=" + encodeURIComponent(to)
            + "&hl=" + encodeURIComponent(uiLang);
}

function googleBody(text)
{
    return "q=" + encodeURIComponent(text);
}

// -> {text, sourceTranslit, targetTranslit, detected, dictionary: [{pos, entries: [{word, reverse}]}]}
// or null when the answer is not Google's JSON
function parseGoogle(body)
{
    var res;
    try {
        res = JSON.parse(body);
    } catch (e) {
        return null;
    }
    if (!res || !res[0])
        return null;
    var out = { "text": "", "sourceTranslit": "", "targetTranslit": "", "detected": "", "dictionary": [] };
    var sentences = res[0];
    for (var i = 0; i < sentences.length; ++i) {
        var s = sentences[i];
        if (s[0] === null || s[0] === undefined) {
            if (s[2]) out.targetTranslit += s[2];
            if (s[3]) out.sourceTranslit += s[3];
        } else {
            out.text += s[0];
        }
    }
    if (res[1]) {
        for (var j = 0; j < res[1].length; ++j) {
            var d = res[1][j];
            var section = { "pos": d[0] || "", "entries": [] };
            var list = d[2] || [];
            for (var k = 0; k < list.length && k < 12; ++k)
                section.entries.push({ "word": list[k][0], "reverse": (list[k][1] || []).join(", ") });
            if (!list.length && d[1])
                for (var m = 0; m < d[1].length && m < 12; ++m)
                    section.entries.push({ "word": d[1][m], "reverse": "" });
            out.dictionary.push(section);
        }
    }
    if (typeof res[2] === "string")
        out.detected = res[2];
    return out;
}

// ---- MyMemory (api.mymemory.translated.net), up to 500 bytes per request ----

function myMemoryCode(code)
{
    return code === "auto" ? "autodetect" : code;
}

function myMemoryPieces(text)
{
    var out = [];
    var limit = 450;
    while (utf8Length(text) > limit) {
        var cut = -1;
        var marks = [". ", "! ", "? ", "\n", "; ", ", ", " "];
        var head = text.substring(0, Math.floor(limit / 2));
        for (var i = 0; i < marks.length; ++i) {
            cut = head.lastIndexOf(marks[i]);
            if (cut > head.length / 3) {
                cut += marks[i].length;
                break;
            }
        }
        if (cut <= 0)
            cut = head.length;
        out.push(text.substring(0, cut));
        text = text.substring(cut);
    }
    if (text.length)
        out.push(text);
    return out;
}

function utf8Length(s)
{
    return unescape(encodeURIComponent(s)).length;
}

function myMemoryUrl(piece, from, to)
{
    return "https://api.mymemory.translated.net/get?q=" + encodeURIComponent(piece)
            + "&langpair=" + encodeURIComponent(myMemoryCode(from) + "|" + myMemoryCode(to));
}

// -> {text, detected} or {error}
function parseMyMemory(body)
{
    var res;
    try {
        res = JSON.parse(body);
    } catch (e) {
        return { "error": "MyMemory" };
    }
    if (!res.responseData || (res.responseStatus && res.responseStatus != 200))
        return { "error": String(res.responseDetails || res.responseStatus || "MyMemory") };
    return { "text": unescapeHtml(res.responseData.translatedText || ""),
             "detected": res.responseData.detectedLanguage || "" };
}

function unescapeHtml(s)
{
    return s.replace(/&#39;/g, "'").replace(/&quot;/g, "\"").replace(/&lt;/g, "<")
            .replace(/&gt;/g, ">").replace(/&amp;/g, "&");
}

// ---- WikDict offline dictionary ----

function dictPair(from, to)
{
    var a = wikdictCode(from), b = wikdictCode(to);
    if (!a || !b || a === b)
        return "";
    return a + "-" + b;
}

// rows from dicts.lookup() -> {dictionary: [...]} in the Google layout
function offlineResult(rows, similarTitle)
{
    var exact = { "pos": "", "entries": [] };
    var similar = { "pos": similarTitle, "entries": [] };
    var first = "";
    for (var i = 0; i < rows.length; ++i) {
        var r = rows[i];
        var entry = { "word": r.word, "reverse": r.trans.split(" | ").join(", ") };
        if (r.exact) {
            exact.entries.push(entry);
            if (!first)
                first = r.trans.split(" | ")[0];
        } else {
            similar.entries.push(entry);
        }
    }
    var dictionary = [];
    if (exact.entries.length) dictionary.push(exact);
    if (similar.entries.length) dictionary.push(similar);
    return { "text": first, "dictionary": dictionary, "found": exact.entries.length > 0 };
}
