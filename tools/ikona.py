from PIL import Image
eye=Image.open('podglad-oko.png').convert('RGBA').resize((70,70),Image.LANCZOS)
bg=Image.open('tlo.png').convert('RGBA').crop((200,340,280,420))
bg.paste(eye,(5,5),eye)
mask=Image.open('n9mask.png').convert('L')
bg.putalpha(mask); bg.save('hal2027-80.png'); bg.resize((240,240),Image.NEAREST).save('ikona-podglad-256.png')
