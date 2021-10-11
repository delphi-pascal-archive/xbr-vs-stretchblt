unit uStretchXBR;
                          //   Redimensionner un BitMap avec la méthode XBR pour un facteur d'échelle de valeur quelconque
                          //   Code expérimental
                          //   Développé sous Selphi-5
                          //   Gilbert GEYER, oct 2012
                          //   Développé par une série de modifications du XBR4bis de Barbichette téléchargeable ici : http://www.delphifr.com/codes/REDIMENSIONNEMENT-XBR_54505.aspx
                          //   Pour la théorie du XBR voir ici : http://board.byuu.org/viewtopic.php?f=10&t=2248


interface

uses Windows, Math, Graphics, Sysutils,Dialogs;

type
  TObjectProc = procedure of object;

function StretchXBR(const BmpS: tBitMap; ScaleFactor: Single; FlouX, FlouY: byte; const ProgressCallBack: TObjectProc = nil): tBitMap;

implementation

// A) UTILITAIRES DIVERS

function ToucheCla(t: integer): boolean; // détection Appui Touche-clavier ou Touche-Souris
//        utilisations : if ToucheCla(VK_CONTROL) then ...
//                       if ToucheCla(Ord('R')) then ...
begin if ((GetAsyncKeyState(t) and 32768) <> 0)
  then Result := true else Result := false;
end;

function IntToByte(i: Integer): Byte;
begin if i > 255 then Result := 255
  else if i < 0 then Result := 0
  else Result := i;
end;

function clQuadEgales(cl1, cl2: tRGBQuad): boolean;
begin Result := (cl1.rgbRed = cl2.rgbRed) and (cl1.rgbGreen = cl2.rgbGreen) and (cl1.rgbBlue = cl2.rgbBlue);
end;

function clQuadVersColor(c3: TRGBQuad): tColor;
begin Result := RGB(c3.rgbRed, c3.rgbGreen, c3.rgbBlue);
end;

function ColorVersClQuad(cl: tColor): tRGBQuad;
begin with Result do begin
    rgbRed := GetRValue(cl);
    rgbGreen := GetGValue(cl);
    rgbBlue := GetBValue(cl);
  end;
end;

function clQuadMix2(c1, c2: tRGBQuad): tRGBQuad;
begin with Result do begin
    rgbRed := (c1.rgbRed + c2.rgbRed) shr 1;
    rgbGreen := (c1.rgbGreen + c2.rgbGreen) shr 1;
    rgbBlue := (c1.rgbBlue + c2.rgbBlue) shr 1;
  end;
end;

function clQuadMix2K(c1, c2: tRGBQuad; k1: Extended): tRGBQuad;
begin with Result do begin
    rgbRed := round(c1.rgbRed * k1 + c2.rgbRed * (1 - k1));
    rgbGreen := round(c1.rgbGreen * k1 + c2.rgbGreen * (1 - k1));
    rgbBlue := round(c1.rgbBlue * k1 + c2.rgbBlue * (1 - k1));
    rgbReserved := round(c1.rgbReserved * k1 + c2.rgbReserved * (1 - k1));
  end;
end;

//----------------------------
type tPointE = record
    x: Single;
    y: Single;
  end;

function PtDansPolygone(Pt: tPointE; Pol: array of tPointE): boolean;
//       Détecter si le point Pt est dans le polygone Pol
//       (utilisable uniquement dans le cas de polygones convexes, tels que des triangles, trapèzes, etc)
var i, j: integer; ok1, ok2: boolean; xl: Single;
begin
  ok1 := false; ok2 := false;
  for i := 0 to High(Pol) do begin
    if i < High(Pol) then j := i + 1 else j := 0;
    if (Pol[i].y <= Pt.y) and (Pol[j].y >= Pt.y) then begin
      if (Pol[j].y <> Pol[i].y)
        then xl := Pol[i].x + (Pol[j].x - Pol[i].x) * (Pt.y - Pol[i].y) / (Pol[j].y - Pol[i].y)
      else xl := min(Pol[j].x, Pol[i].x);
      if (Pt.x >= xl) then begin ok1 := True; break; end;
    end;
  end;
  for i := 0 to High(Pol) do begin
    if i < High(Pol) then j := i + 1 else j := 0;
    if (Pol[i].y >= Pt.y) and (Pol[j].y <= Pt.y) then begin
      if (Pol[i].y <> Pol[j].y)
        then xl := Pol[i].x - (Pol[i].x - Pol[j].x) * (Pol[i].y - Pt.y) / (Pol[i].y - Pol[j].y)
      else xl := max(Pol[j].x, Pol[i].x);
      if (Pt.x <= xl) then begin ok2 := True; break; end;
    end;
  end;
  Result := ok1 and ok2;
end;

procedure RotatePoly(var Pol: array of TPointE; const cRota: TPointE; iRota: byte);
//        Rotation d'un polygone
//        iRota = 2 -> rotation de -Pi/2, iRota = 3 -> -Pi, iRota = 4 -> -3*Pi/2
var j: integer; Rxx, Ryy: Single; cosi, sinu: ShortInt;
begin
  case iRota of
    2: begin cosi := 0; sinu := -1; end;
    3: begin cosi := -1; sinu := 0; end;
    4: begin cosi := 0; sinu := +1; end;
  else EXIT;
  end;
  for j := 0 to High(Pol) do begin
    Rxx := Pol[j].x - cRota.x; Ryy := Pol[j].y - cRota.y;
      // Application de la matrice de rotation par rapport au centre cr
    Pol[j].x := cRota.x + (Rxx * cosi - Ryy * sinu);
    Pol[j].y := cRota.y + (Rxx * sinu + Ryy * cosi);
  end;
end;

function DistancePtDroiteE(OD, ED, Pt: TPointE): Single;
//       OD et OE = origine et extrémité de la droite, Pt = point dont on cherche la distance par rapport à cette droite
var a, b, dx, dy: Single;
begin dx := ED.x - OD.x; dy := ED.y - OD.y;
  if dx = 0 then begin Result := abs(Pt.x - OD.x); EXIT; end; // D verticale
  if dy = 0 then begin Result := abs(Pt.y - OD.y); EXIT; end; // D horizontale
  // D inclinée
  a := dy / dx; b := ED.y - ED.x * a; // y = a*x +b
  Result := abs(a * Pt.x - Pt.y + b) / sqrt(1 + a * a);
end;

// B) la méthode XBR pour un ScaleFoctor de valeur quelconque ------------------

function StretchXBR(const BmpS: tBitMap; ScaleFactor: Single; FlouX, FlouY: byte; const ProgressCallBack: TObjectProc = nil): tBitMap;
type
  tScanYX = array of array of integer; // Tableaux des adresses des pixels
  Tvoisins = array[-2..2, -2..2] of tRGBQuad;
const R2: Single = 1.41421356737;
var
  xs, ys, xoutMin, youtMin, Lig, Col: integer;
  nl, nl1, nl2: integer;
  Voisins: Tvoisins;

  Rouge, Bleu, Vert, Jaune, Fuchsia, Aqua: tRGBQuad;
  kech: single;
  ikech: integer;
  mikech, mikechR2, mikechR2sur2, dbMaxLeft_2, xzMin, xzMax, yzMin, yzMax: Single;
  Dia, UP_2, Left_2, Left_UP_2: array[0..2] of TPointE;
  cr: TPointE; // Centre de rotation
  Stop: boolean;

  WS, HS: integer; pt: TPoint;
  WR, HR: integer;

  pixS, pixR: tScanYX;

  bm_T: tBitMap; // Bitmap temporaire pour cas de ScaleFactor de valeur non entière

const
  pg_red_mask = $FF0000;
  pg_green_mask = $00FF00;
  pg_blue_mask = $0000FF;
  pg_lbmask = $FEFEFE;

  procedure Initialisations; // Initialisation des BitMaps et des paramètres constants
  var x, y: integer;
    Scan0: Integer; // Valeur du pointeur d'entrée dans le Bitmap.
    MLS: Integer; //   Memory Line Size (en bytes) du Bitmap.
    Bpp: Integer; //   Bytes par pixel des Bitmaps.
  begin
    iKech := round(Kech);
    miKech := Kech / 2;
    mikechR2 := miKech * R2;
    mikechR2sur2 := mikechR2 / 2;
    dbMaxLeft_2 := 0.894427191 * mikech; // 0.894427191 = sinus(arcTan(2/1))
    with CR do begin x := mikech; y := mikech; end;
    // BitMap-Source
    BmpS.PixelFormat := pf32bit; Bpp := 4; Scan0 := Integer(BmpS.ScanLine[0]); MLS := Integer(BmpS.ScanLine[1]) - Scan0;
    WS := BmpS.Width; HS := BmpS.Height;
    SetLength(pixS, HS, WS);
    for y := 0 to HS - 1 do begin
      for x := 0 to WS - 1 do pixS[y, x] := Scan0 + y * MLS + x * Bpp;
    end;
    // BitMap-result
    Result := tBitMap.Create; kech := abs(kech);
    WR := iKech * WS; HR := iKech * HS;
    with Result do begin PixelFormat := pf32bit; width := WR; height := HR end;
    Scan0 := Integer(Result.ScanLine[0]); MLS := Integer(Result.ScanLine[1]) - Scan0;
    SetLength(pixR, HR, WR);
    for y := 0 to HR - 1 do begin
      for x := 0 to WR - 1 do begin
        pixR[y, x] := Scan0 + y * MLS + x * Bpp;
        PRGBQuad(pixR[y, x])^ := ColorVersClQuad(clWhite);
        PRGBQuad(pixR[y, x])^.rgbReserved := 0;
      end;
    end;
    Rouge := ColorVersClQuad(clRed);
    Bleu := ColorVersClQuad(clBlue);
    Vert := ColorVersClQuad(clGreen);
    Jaune := ColorVersClQuad(clYellow);
    Fuchsia := ColorVersClQuad(clFuchsia);
    Aqua := ColorVersClQuad(clAqua);
  end;

  function RGBtoYUV(c: longint): longint;
  //       Conversion de l'espace colorimétrique RGB vers l'espace YUV
  var r, g, b, y, u, v: cardinal;
  begin
    r := (c and pg_red_mask) shr 16;
    g := (c and pg_green_mask) shr 8;
    b := (c and pg_blue_mask);
    y := ((r shl 4) + (g shl 5) + (b shl 2)); // Y = Luminance
    u := (-r - (g shl 1) + (b shl 2));        // U et V = Chrominance
    v := ((r shl 1) - (g shl 1) - (b shl 1));
    result := y + u + v;
  end;

  function ClQuadVerscLongint(c: tRGBQuad): longint;
  // Simple conversion d'une couleur du type RGBQuad vers le type longint utilisé par RGBtoYUV
  var r, g, b: cardinal;
  begin
    Result := (c.rgbRed shl 16) + (c.rgbGreen shl 8) + c.rgbBlue;
  end;

  function df(A, B: tRGBQuad): longint;
  var AL, BL: longint;
  begin
    AL := ClQuadVerscLongint(A); BL := ClQuadVerscLongint(B);
    result := abs(RGBtoYUV(Al) - RGBtoYUV(BL));
    // Result renvoie une valeur qui augmente lorsque la couleur A contraste de plus en plus avec celle de la couleur B
    // Result-maxi = 13005 dans le cas d'un contraste maxi Noir/Blanc.
  end;

  function eq(A, B: tRGBQuad): boolean;
  begin
    result := df(A, B) < 155;
  end;

  function ifThenClQuad(condition: boolean; OK: tRGBQuad; NOK: tRGBQuad): tRGBQuad;
  begin
    if condition then result := OK else result := NOK;
  end;

  procedure Rotate(var matrice: Tvoisins); // Rotation de la matrice des couleurs voisines dans le sens des aiguilles d'une montre.
  var tmp: Tvoisins; Co, Li: integer;
  begin
    for Li := -2 to 2 do
      for Co := -2 to 2 do
        tmp[-Li, Co] := matrice[Co, Li];
    matrice := tmp;
  end;

  procedure SetPixelOut(xx, yy: integer; px: tRGBQuad);
  begin
    if (xx >= 0) and (yy >= 0) and (xx < WR) and (yy < HR) then PRGBQuad(pixR[yy, xx])^ := px;
  end;

  procedure OptionFlou(TraineeX, TraineeY: byte);
  var X, Y, Z: Integer; clm: tRGBQuad;
  begin
    if (TraineeX = 0) and (TraineeY = 0) then EXIT;
    for Z := 1 to TraineeX do // décalage de trainéeX pixels :
    begin for Y := 0 to HR - 1 do
      begin for X := 0 to WR - TraineeX - 1 do begin
          clm := clQuadMix2(PRGBQuad(pixR[Y, X])^, PRGBQuad(pixR[Y, X + 1])^); // moyenne du pixel avec le suivant
          SetPixelOut(X + 1, Y, clm);
        end;
      end;
    end;
    if TraineeY = 0 then EXIT;
    for Z := 0 to TraineeY - 1 do // décalage de trainéeY pixels :
    begin for y := 0 to HR - TraineeY - 1 do
      begin for X := 0 to WR - 1 do begin
          clm := clQuadMix2(PRGBQuad(pixR[Y, X])^, PRGBQuad(pixR[Y + 1, X])^); // moyenne du pixel avec le suivant
          SetPixelOut(X, Y + 1, clm);
        end;
      end;
    end;
  end; // OptionFlou

  procedure TraceLeft_UP_2(xx, yy: integer; iRot: integer; nc: tRGBQuad);
  //        Dégradé de couleurs dans le coin-de-surface-moitié-du-carré s'il a été détecté un bord à 45° le nécessitant
  var Pt: TPointE; x, y, dx, dy, db, kcl: Single; clm: tRGBQuad;
    ix, iy, i, j: integer;
  begin
    //¨Pour iRot=1 Coin Sud-Est :
    with Left_UP_2[0] do begin x := kech; y := 0.0; end;
    with Left_UP_2[1] do begin x := 0.0; y := kech; end;
    with Left_UP_2[2] do begin x := kech; y := kech; end; //nc := Bleu;
    //¨Pour iRot<> 1 autre coins : rotation
    if iRot <> 1 then RotatePoly(Left_UP_2, CR, iRot);

    dy := 0.0; clm := voisins[0, 0];
    while dy < Kech do begin
      dx := 0.0; Pt.y := dy;
      while dx < Kech do begin
        Pt.x := dx;
        if PtDansPolygone(Pt, Left_UP_2) then begin
          db := DistancePtDroiteE(Left_UP_2[0], Left_UP_2[1], Pt);
          kcl := db / mikechR2;
          clm := clQuadMix2K(nc, clm, kcl);
          iy := trunc(yy + dy);
          ix := round(xx + dx);
          SetPixelOut(ix, iy, clm);
        end;
        dx := dx + 0.5;
      end;
      dy := dy + 0.5;
    end;
  end; // TraceLeft_UP_2

  procedure TraceDia(xx, yy: integer; iRot: integer; nc: tRGBQuad);
  //        Dégradé de couleurs dans le coin-de-surface-huitième-du-carré s'il a été détecté un bord à 45° le nécessitant
  var Pt: TPointE; x, y, dx, dy, dhyp, kcl: Single;
    ix, iy, i, j: integer; clm: tRGBQuad;
  begin
    // Pour iRot = 1 :
    with Dia[0] do begin x := kech; y := mikech + 1.0; end;
    with Dia[1] do begin x := mikech + 1.0; y := kech; end;
    with Dia[2] do begin x := kech; y := kech; end;
    if iRot <> 1 then RotatePoly(Dia, CR, iRot);

    dy := 0.0; //clm := voisins[0, 0];
    while dy < Kech do begin
      dx := 0.0; Pt.y := dy;
      while dx < Kech do begin
        Pt.x := dx;
        if PtDansPolygone(Pt, Dia) then begin
          iy := trunc(yy + dy);
          ix := trunc(xx + dx);
          dhyp := DistancePtDroiteE(Dia[0], Dia[1], Pt);
          kcl := dhyp / mikechR2sur2;
          if kcl > 1.0 then kcl := 1.0;
          clm := clQuadMix2K(clm, nc, kcl);
          SetPixelOut(ix, iy, clm);
          //SetPixelOut(ix, iy, nc);
        end;
        dx := dx + 0.5;
      end;
      dy := dy + 0.5;
    end;
  end; // TraceDia

  procedure TraceUP_2(xx, yy: integer; iRot: integer; nc: tRGBQuad);
  //        Dégradé de couleurs dans le coin-de-surface-quart-du-carré s'il a été détecté un bord à 26,56° le nécessitant
  var Pt: TPointE; x, y, dx, dy, db, dbMax, kcl: Single;
    ix, iy, i, j: integer; clm: tRGBQuad;
  begin
    // Pour iRot = 1 :
    with UP_2[0] do begin x := kech; y := mikech; end;
    with UP_2[1] do begin x := 0.0; y := kech; end;
    with UP_2[2] do begin x := kech; y := kech; end; //nc := Bleu;
    if iRot <> 1 then RotatePoly(UP_2, CR, iRot);

    clm := voisins[0, 0];
    dy := 0.0; dbMax := 0.894427191 * mikech; // 0.894427191 = sinus(arcTan(2/1))
    while dy < Kech do begin
      dx := 0.0;
      while dx < Kech do begin
        Pt.x := dx; Pt.y := dy;
        iy := trunc(yy + dy);
        ix := trunc(xx + dx);
        if PtDansPolygone(Pt, UP_2) then begin
          db := DistancePtDroiteE(UP_2[0], UP_2[1], Pt);
          kcl := db / dbMax;
          clm := clQuadMix2K(nc, clm, kcl);
          if db < 0.71 then SetPixelOut(ix, iy, clQuadMix2(nc, clm))
          else SetPixelOut(ix, iy, clm);
        end;
        dx := dx + 0.5;
      end;
      dy := dy + 0.5;
    end;
  end; // TraceUP_2

  procedure TraceLeft_2(xx, yy: integer; iRot: integer; nc: tRGBQuad);
  //        Dégradé de couleurs dans le coin-de-surface-quart-du-carré s'il a été détecté un bord à 63,43° le nécessitant
  var Pt: TPointE; x, y, dx, dy, db, kcl: Single;
    ix, iy, i, j: integer; clm: tRGBQuad;
  begin
    //¨Pour iRot=1 Coin Sud-Est :
    with Left_2[0] do begin x := kech; y := 0.0; end;
    with Left_2[1] do begin x := mikech; y := kech; end;
    with Left_2[2] do begin x := kech; y := kech; end;
    if iRot <> 1 then RotatePoly(Left_2, CR, iRot);

    dy := 0.0; clm := voisins[0, 0];
    while dy < Kech do begin
      dx := 0.0; Pt.y := dy;
      while dx < Kech do begin
        Pt.x := dx;
        if PtDansPolygone(Pt, Left_2) then begin
          db := DistancePtDroiteE(Left_2[0], Left_2[1], Pt);
          kcl := db / dbMaxLeft_2;
          clm := clQuadMix2K(nc, clm, kcl);
          iy := trunc(yy + dy);
          ix := trunc(xx + dx);
          SetPixelOut(ix, iy, clm);
        end;
        dx := dx + 0.5;
      end;
      dy := dy + 0.5;
    end;
  end; // TraceLeft_2

  procedure FILTRE_KXBR(iRota: integer; v: Tvoisins);
  var
    ex2, ex3: boolean;
    le, li: integer;
    ke, ki: integer; px: tRGBQuad;
  begin
    // les voisins sont-ils de la même couleur ?
    // si oui, on ne fait rien : le carré reste entièrement de la même couleur que le voisins[0, 0]
    if (clQuadEgales(v[0, 0], v[0, 1])) or (clQuadEgales(v[0, 0], v[1, 0])) then EXIT;
    // si non, recherche des bords :

    le := (df(v[1, -1], v[0, 0]) + df(v[0, 0], v[-1, 1]) + df(v[0, 2], v[1, 1]) + df(v[1, 1], v[2, 0])) + (df(v[0, 1], v[1, 0]) shl 2);
    li := (df(v[-1, 0], v[0, 1]) + df(v[0, 1], v[1, 2]) + df(v[0, -1], v[1, 0]) + df(v[1, 0], v[2, 1])) + (df(v[0, 0], v[1, 1]) shl 2);
    // si le < li : bord globalement du bas gauche vers haut droit : Sud-Est
    // les autres sens seront traité lors des rotations

    if (le < li) and ((not eq(v[1, 0], v[0, -1]) and not eq(v[1, 0], v[1, -1]))
      or (not eq(v[0, 1], v[-1, 0]) and not eq(v[0, 1], v[-1, 1]))
      or (eq(v[0, 0], v[1, 1])
      and ((not eq(v[1, 0], v[2, 0]) and not eq(v[1, 0], v[2, 1]))
      or (not eq(v[0, 1], v[0, 2]) and not eq(v[0, 1], v[1, 2]))))
      or eq(v[0, 0], v[-1, 1])
      or eq(v[0, 0], v[1, -1])) then
    begin
      ke := df(v[1, 0], v[-1, 1]);
      ki := df(v[0, 1], v[1, -1]);
      ex2 := (not clQuadEgales(v[0, 0], v[1, -1])) and (not clQuadEgales(v[0, -1], v[1, -1]));
      ex3 := (not clQuadEgales(v[0, 0], v[-1, 1])) and (not clQuadEgales(v[-1, 0], v[-1, 1]));

      // On choisit la nouvelle couleur à appliquer
      px := ifThenClQuad((df(v[0, 0], v[1, 0]) <= df(v[0, 0], v[0, 1])), v[1, 0], v[0, 1]);

      if ((ke shl 1) <= ki) and ex3 and (ke >= (ki shl 1)) and ex2 then
      begin // LEFT_UP_2
        TraceLeft_UP_2(xoutMin, youtMin, iRota, px);
      end else
        if ((ke shl 1) <= ki) and ex3 then
        begin // UP_2 (ancien LEFT_2)
          TraceUP_2(xoutMin, youtMin, iRota, px);
        end else
          if (ke >= (ki shl 1)) and ex2 then
          begin // LEFT_2 (ancien UP_2)
            TraceLEFT_2(xoutMin, youtMin, iRota, px);
          end else
          begin // DIA
            TraceDIA(xoutMin, youtMin, iRota, px);
          end
    end else
      if le <= li then begin // Pointes d'angles
        px := ifThenClQuad(df(v[0, 0], v[1, 0]) <= df(v[0, 0], v[0, 1]), v[1, 0], v[0, 1]);
        px := clQuadMix2(px, v[0, 0]);
        case iRota of
          1: SetPixelOut(xs * ikech + ikech - 1, ys * ikech + ikech - 1, px);
          2: SetPixelOut(xs * ikech + ikech - 1, ys * ikech, px);
          3: SetPixelOut(xs * ikech, ys * ikech, px);
          4: SetPixelOut(xs * ikech, ys * ikech + ikech - 1, px);
        end;
      end;
  end; // FILTRE_KX

  function getPixelIn(xx, yy: integer): tRGBQuad;
  begin
    if xx < 0 then xx := 0;
    if yy < 0 then yy := 0;
    if xx >= WS then xx := WS - 1;
    if yy >= HS then yy := HS - 1;
    result := PRGBQuad(pixS[yy, xx])^;
  end;

begin
  ScaleFactor := abs(ScaleFactor);
  if ScaleFactor >= 8.0
    then Kech := Scalefactor
  else Kech := 8.0; // Si ScaleFactor est < 8 on procède à un XBR avec 8 et qui sera suivi d'un ajustement de taille rapide avec StretchBlt
  Initialisations;

  for ys := 0 to HS - 1 do begin
    for xs := 0 to WS - 1 do begin

      for Col := -2 to 2 do
        for Lig := -2 to 2 do begin
          voisins[Col, Lig] := getPixelIn(xs + Col, Lig + ys);
        end;

      for Col := 0 to iKech - 1 do // Tracé préalable du carré plein monochrome avant détection de bords
        for Lig := 0 to iKech - 1 do
          SetPixelOut(xs * iKech + Col, ys * iKech + Lig, voisins[0, 0]);

      xoutMin := xs * ikech; youtMin := ys * ikech; // Angle Supérieur Gauche du carré à traiter

      FILTRE_KXBR(1, voisins);
      Rotate(voisins);
      FILTRE_KXBR(2, voisins);
      Rotate(voisins);
      FILTRE_KXBR(3, voisins);
      Rotate(voisins);
      FILTRE_KXBR(4, voisins);
      //SetPixelOut(xoutMin, youtMin, Rouge); //Visu de la Trame
    end;
    if ToucheCla(VK_ESCAPE) then EXIT;
    if Assigned(ProgressCallBack) then ProgressCallBack;
  end;

  if (FlouX <> 0) or (FlouY <> 0) then OptionFlou(FlouX, FlouY);
  if iKech <> ScaleFactor then begin // Ajustement de taille si ScaleFactor n'est pas une valeur entière ou s'il est inférieur à 8
    bm_T := tBitMap.create;
    WR := round(ScaleFactor * WS); HR := round(ScaleFactor * HS);
    with bm_T do begin width := WR; height := HR; pixelFormat := pf32bit; end;

    if GetStretchBltMode(bm_T.Canvas.Handle) <> HalfTone then
    begin GetBrushOrgEx(bm_T.Canvas.Handle, pt);
      SetStretchBltMode(bm_T.Canvas.Handle, HalfTone);
      SetBrushOrgEx(bm_T.Canvas.Handle, pt.x, pt.y, @pt);
    end;
    StretchBlt(bm_T.Canvas.Handle, 0, 0, WR, HR,
      Result.Canvas.Handle, 0, 0, Result.Width, Result.height, SRCCOPY);
    Result.Assign(bm_T);
    bm_T.free;
  end;
end; // StretchXBR

END. ///////////////////////////////////////////////////////////////////////////
