from PIL import Image, ImageDraw, ImageFont

S = 3
W, H = 832, 900
im = Image.new('RGB', (W*S, H*S), '#18181a')
d = ImageDraw.Draw(im)

FONT = 'C:/Windows/Fonts/segoeui.ttf'
BOLD = 'C:/Windows/Fonts/segoeuib.ttf'
MONO = 'C:/Windows/Fonts/consola.ttf'

def font(size, bold=False, mono=False):
    return ImageFont.truetype(MONO if mono else BOLD if bold else FONT, size*S)

def box(x0,y0,x1,y1,fill,r=0,outline=None,width=1):
    xy=(int(x0*S),int(y0*S),int(x1*S),int(y1*S))
    if r:
        d.rounded_rectangle(xy,radius=r*S,fill=fill,outline=outline,width=width*S)
    else:
        d.rectangle(xy,fill=fill,outline=outline,width=width*S)

def line(points,fill,width=1):
    d.line([(int(x*S),int(y*S)) for x,y in points],fill=fill,width=width*S,joint='curve')

def circle(x,y,r,fill,outline=None,width=1):
    d.ellipse((int((x-r)*S),int((y-r)*S),int((x+r)*S),int((y+r)*S)),fill=fill,outline=outline,width=width*S)

def txt(x,y,t,size=16,fill='#ededee',bold=False,mono=False,anchor=None):
    d.text((int(x*S),int(y*S)),t,font=font(size,bold,mono),fill=fill,anchor=anchor)

def chevron(x,y,fill='#a8a9ad'):
    line([(x-3,y-5),(x+2,y),(x-3,y+5)],fill,2)

def bubble(x,y,color='#c8102e'):
    box(x-10,y-8,x+10,y+7,None,5,color,2)
    line([(x-5,y+7),(x-5,y+11),(x,y+7)],color,2)
    for dx in [-5,0,5]: circle(x+dx,y,1.2,color)

def briefcase(x,y,color='#c8102e'):
    box(x-10,y-5,x+10,y+9,None,2,color,2)
    box(x-4,y-10,x+4,y-5,None,1,color,2)
    line([(x-10,y),(x+10,y)],color,1)

def star(x,y,color='#77787d'):
    # Tiny outline star, drawn manually for consistent icon weight.
    line([(x,y-10),(x+3,y-3),(x+10,y-3),(x+5,y+2),(x+7,y+9),(x,y+5),(x-7,y+9),(x-5,y+2),(x-10,y-3),(x-3,y-3),(x,y-10)],color,2)

def board(x):
    box(x,0,x+390,76,'#0d0d0d')
    txt(x+7,3,'☼ DAY 1  MORNING',15,'#f3b31b',True,True)
    txt(x+7,24,'□□□  £100000',16,'#f3b31b',True,True)
    box(x+360,33,x+373,45,None,2,'#e8a818',2)
    line([(x+363,33),(x+365,29),(x+369,29),(x+371,33)],'#e8a818',2)

def dock(x):
    box(x,776,x+390,840,'#fdfdfd')
    line([(x,776),(x+390,776)],'#dadada',1)
    for cx,label in [(x+65,'Phone'),(x+195,'Map'),(x+325,'HQ')]:
        txt(cx,816,label,12,'#c8102e',anchor='mt')
    box(x+60,790,x+70,807,None,1,'#c8102e',2)
    line([(x+63,804),(x+67,804)],'#c8102e',1)
    circle(x+195,796,5,None,'#c8102e',2)
    circle(x+195,796,1.5,'#c8102e')
    line([(x+192,800),(x+195,807),(x+198,800)],'#c8102e',2)
    line([(x+318,796),(x+325,790),(x+332,796)],'#c8102e',2)
    box(x+320,796,x+330,807,None,0,'#c8102e',2)
    line([(x+324,807),(x+324,801),(x+327,801),(x+327,807)],'#c8102e',1)
    line([(x+130,792),(x+130,824)],'#dbdbdb')
    line([(x+260,792),(x+260,824)],'#dbdbdb')

def shell(x):
    box(x+4,84,x+386,770,'#101114',31,'#44464b',2)
    box(x+10,90,x+380,764,'#252528',25)
    # Decorative phone status bar, retained inside opened apps.
    txt(x+29,98,'08:14',14,'#ededee',True)
    for i,h in enumerate([4,6,8,10]):
        box(x+272+i*5,115-h,x+275+i*5,115,'#ededee',1)
    line([(x+301,107),(x+309,103),(x+317,107)],'#ededee',2)
    line([(x+305,111),(x+309,109),(x+313,111)],'#ededee',2)
    circle(x+309,114,1.3,'#ededee')
    box(x+326,102,x+348,115,None,3,'#ededee',1)
    box(x+349,106,x+351,111,'#ededee',1)
    box(x+328,104,x+345,113,'#ededee',1)
    txt(x+355,99,'87%',10,'#ededee')
    box(x+160,747,x+230,751,'#d4d4d6',3)

def contact_row(x,top,initial,name,desc,relation,avatar):
    circle(x+55,top+41,25,avatar)
    txt(x+55,top+41,initial,23,'#f4f4f4',True,anchor='mm')
    txt(x+96,top+12,name,19,'#ededee',True)
    txt(x+96,top+40,desc,14,'#9b9ca1')
    box(x+258,top+20,x+338,top+49,'#343438',15)
    txt(x+298,top+34,'Rel. '+str(relation),12,'#d6d6d8',True,anchor='mm')
    chevron(x+354,top+36)
    line([(x+96,top+81),(x+363,top+81)],'#424246')

def action_row(x,y,label,icon,enabled=True,subtitle=None):
    box(x+26,y,x+364,y+62 if subtitle is None else y+77,'#303034' if enabled else '#2b2b2e',12)
    if icon=='bubble': bubble(x+55,y+31,'#c8102e' if enabled else '#77787d')
    if icon=='briefcase': briefcase(x+55,y+30,'#c8102e' if enabled else '#77787d')
    if icon=='star': star(x+55,y+31,'#77787d')
    txt(x+81,y+17,label,17,'#ededee' if enabled else '#a1a2a6',True)
    if subtitle:
        txt(x+81,y+44,subtitle,13,'#85868b')
    elif enabled:
        chevron(x+340,y+31)

def screen(x,detail=False):
    board(x); dock(x); shell(x)
    txt(x+27,145,'‹',29,'#c8102e')
    txt(x+49,155,'Contacts' if detail else 'Phone',15,'#c8102e')
    if not detail:
        txt(x+27,192,'Contacts',32,'#f2f2f3',True)
        txt(x+27,249,'A',13,'#999a9d',True)
        line([(x+27,273),(x+363,273)],'#424246')
        contact_row(x,278,'A','Archie','Trader · Whitechapel',60,'#70444d')
        txt(x+27,382,'J',13,'#999a9d',True)
        line([(x+27,406),(x+363,406)],'#424246')
        contact_row(x,411,'J','James','Craftsman · Bermondsey',40,'#465b68')
        txt(x+27,535,'Tap a contact to see actions',13,'#77787d')
    else:
        circle(x+195,242,47,'#70444d')
        txt(x+195,241,'A',43,'#f4f4f4',True,anchor='mm')
        txt(x+195,306,'Archie',30,'#f2f2f3',True,anchor='mt')
        txt(x+195,350,'Trader · Whitechapel',15,'#a7a8ac',anchor='mt')
        box(x+148,391,x+242,421,'#37373b',15)
        txt(x+195,405,'Relation 60',13,'#e9e9ea',True,anchor='mm')
        line([(x+26,447),(x+364,447)],'#424246')
        action_row(x,470,'Messages','bubble')
        action_row(x,545,'Trade','briefcase')
        action_row(x,620,'Recruit Archie','star',False,'20 more relation needed')

txt(28,31,'DIRECTORY',13,'#b0b1b5',True)
txt(444,31,'CONTACT DETAIL',13,'#b0b1b5',True)
screen(14,False)
screen(428,True)
im.save('.scratch/contacts-ui-concept/contacts_mockup.png')

# Follow-up concept: contact actions stay in the directory.
im = Image.new('RGB', (390*S, 840*S), '#18181a')
d = ImageDraw.Draw(im)
board(0); dock(0); shell(0)
txt(27,145,'‹',29,'#c8102e')
txt(49,155,'Phone',15,'#c8102e')
txt(27,192,'Contacts',32,'#f2f2f3',True)

def inline_contact(y,initial,name,desc,relation,avatar):
    circle(54,y+31,25,avatar)
    txt(54,y+31,initial,22,'#f4f4f4',True,anchor='mm')
    txt(96,y+2,name,19,'#ededee',True)
    txt(96,y+30,desc,14,'#9b9ca1')
    box(286,y+13,362,y+43,'#37373b',15)
    txt(324,y+27,'Rel. '+str(relation),12,'#e1e1e3',True,anchor='mm')

def quick_button(x,y,w,label,icon,enabled=True,hint=None):
    box(x,y,x+w,y+76,'#36363a' if enabled else '#2c2c2f',12)
    col='#c8102e' if enabled else '#78797e'
    cx=x+w/2
    if icon=='bubble': bubble(cx,y+21,col)
    elif icon=='briefcase': briefcase(cx,y+21,col)
    else: star(cx,y+21,col)
    txt(cx,y+39,label,13,'#ededee' if enabled else '#aaaab0',True,anchor='mt')
    if hint: txt(cx,y+58,hint,10,'#8d8e92',anchor='mt')

txt(27,249,'A',13,'#999a9d',True)
line([(27,274),(363,274)],'#424246')
inline_contact(286,'A','Archie','Trader · Whitechapel',60,'#70444d')
quick_button(27,363,105,'Messages','bubble')
quick_button(139,363,105,'Trade','briefcase')
quick_button(251,363,112,'Recruit','star',False,'20 more rel.')

txt(27,468,'J',13,'#999a9d',True)
line([(27,493),(363,493)],'#424246')
inline_contact(505,'J','James','Craftsman · Bermondsey',40,'#465b68')
quick_button(27,582,162,'Messages','bubble')
quick_button(197,582,166,'Recruit','star',False,'60 more rel.')

im.save('.scratch/contacts-ui-concept/contacts_mockup_inline.png')
