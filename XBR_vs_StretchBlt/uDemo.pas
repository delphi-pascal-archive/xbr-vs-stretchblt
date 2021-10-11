unit uDemo;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ExtDlgs, ComCtrls, Math, uStretchXBR, Menus,
  Buttons, ShellAPI;

type
  TFrmDemoMain = class(TForm)
    OpenPictureDialog1: TOpenPictureDialog;
    SavePictureDialog1: TSavePictureDialog;
    Notebook1: TNotebook;
    PanelHaut: TPanel;
    lblScaleValue: TLabel;
    bAide: TSpeedButton;
    btnDoOpenBMP: TSpeedButton;
    btnSaveBitmap: TSpeedButton;
    lblOriginalValue: TLabel;
    lblResizedValue: TLabel;
    edFileName1: TEdit;
    TrackBar1: TTrackBar;
    GroupBox2: TGroupBox;
    bStretchBlt_HALFTONE: TSpeedButton;
    bStretchBltSansHalftone: TSpeedButton;
    bStretchXBR: TSpeedButton;
    Bevel1: TBevel;
    Label1: TLabel;
    Label2: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    edFlouX: TEdit;
    edFlouY: TEdit;
    ckbAjouterFlou: TCheckBox;
    ProgressBar1: TProgressBar;
    edMis: TEdit;
    Panel2: TPanel;
    Splitter1: TSplitter;
    ScrollBox1: TScrollBox;
    imgOriginal: TImage;
    ScrollBox2: TScrollBox;
    imgResized: TImage;
    RE: TRichEdit;
    imgCarre: TImage;
    bRetour: TSpeedButton;
    labLienURL: TLabel;
    imgLeft_UP_2: TImage;
    imgDIA: TImage;
    imgUp_2: TImage;
    imgLeft_2: TImage;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Up_2: TLabel;
    Label7: TLabel;
    imgAAhaut: TImage;
    imgAAbas: TImage;
    Label6: TLabel;
    Label8: TLabel;
    Label11: TLabel;
    RE1: TRichEdit;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    procedure Splitter1Moved(Sender: TObject);
    procedure lblScaleValueClick(Sender: TObject);
    procedure bRetourClick(Sender: TObject);
    procedure bStretchBlt_HALFTONEClick(Sender: TObject);
    procedure bStretchBltSansHalftoneClick(Sender: TObject);
    procedure bStretchXBRClick(Sender: TObject);
    procedure edFlouXChange(Sender: TObject);
    procedure edFlouYChange(Sender: TObject);
    procedure bAideClick(Sender: TObject);
    procedure labLienURLDblClick(Sender: TObject);
    procedure btnDoOpenBMPClick(Sender: TObject);
    procedure btnSaveBitmapClick(Sender: TObject);
  private
    { Déclarations privées }
    procedure SetScale;
  public
    { Déclarations publiques }
  end;

var
  FrmDemoMain: TFrmDemoMain;

implementation

{$R *.dfm}

var
  aBmp: TBitmap;
  FN: string;
  ScaleValue: Extended = 1.0;
  GTC: DWord;
  FlouX, FlouY: byte;

procedure DoStretchBlt(HalfTon: boolean);
var pt: TPoint;
begin
  with FrmDemoMain do begin
    edMis.text := ''; edMis.Update;
    GTC := GetTickCount;
    if HalfTon then
      if GetStretchBltMode(imgResized.Picture.Bitmap.Canvas.Handle) <> HalfTone then
      begin GetBrushOrgEx(imgResized.Picture.Bitmap.Canvas.Handle, pt);
        SetStretchBltMode(imgResized.Picture.Bitmap.Canvas.Handle, HalfTone);
        SetBrushOrgEx(imgResized.Picture.Bitmap.Canvas.Handle, pt.x, pt.y, @pt);
      end;

    StretchBlt(imgResized.Picture.Bitmap.Canvas.Handle, 0, 0,
      imgResized.Picture.Bitmap.Width, imgResized.Picture.Bitmap.Height,
      imgOriginal.Picture.Bitmap.Canvas.Handle, 0, 0,
      imgOriginal.Picture.Bitmap.Width, imgOriginal.Picture.Bitmap.Height, SRCCOPY);
    edMis.text := 'StretchBlt Mis : ' + intToStr(GetTickCount - GTC) + ' ms';
    imgResized.Invalidate;
  end;
end;

procedure TFrmDemoMain.bStretchBlt_HALFTONEClick(Sender: TObject);
begin DoStretchBlt(True);
end;

procedure TFrmDemoMain.bStretchBltSansHalftoneClick(Sender: TObject);
begin DoStretchBlt(False);
end;

procedure TFrmDemoMain.bStretchXBRClick(Sender: TObject);
var bmp: tBitMap;
begin
  with FrmDemoMain do begin
    edMis.text := ''; edMis.Update;
    GTC := GetTickCount;
    if ckbAjouterFlou.Checked
      then bmp := StretchXBR(imgOriginal.Picture.Bitmap, ScaleValue, FlouX, FlouY, ProgressBar1.StepIt)
    else bmp := StretchXBR(imgOriginal.Picture.Bitmap, ScaleValue, 0, 0, ProgressBar1.StepIt);
    imgResized.Picture.Bitmap.Assign(bmp);
    edMis.text := 'StretchXBR Mis : ' + intToStr(GetTickCount - GTC) + ' ms';
    imgResized.Invalidate;
    ProgressBar1.position := 0;
    bmp.free;
  end;
end;

procedure TFrmDemoMain.btnDoOpenBMPClick(Sender: TObject);
begin if OpenPictureDialog1.Execute then
  begin
    FN := OpenPictureDialog1.FileName; edFileName1.Text := FN;
    imgOriginal.Picture.Bitmap.LoadFromFile(OpenPictureDialog1.FileName);
    TrackBar1Change(self);
    TrackBar1.SetFocus;
  end;

end;

procedure TFrmDemoMain.FormCreate(Sender: TObject);
begin
  aBmp := TBitmap.Create;
  imgResized.Picture.Bitmap := aBmp;
  TrackBar1Change(self);
  imgResized.Picture.Bitmap.Canvas.Pixels[0, 0] := imgResized.Picture.Bitmap.Canvas.Pixels[0, 0];
  FN := '';
  FlouX := StrToInt(edFlouX.text);
  FlouY := StrToInt(edFlouY.text);
end;

procedure TFrmDemoMain.FormDestroy(Sender: TObject);
begin
  aBmp.Free;
end;

procedure TFrmDemoMain.lblScaleValueClick(Sender: TObject);
begin
  TrackBar1.SetFocus;
end;

procedure TFrmDemoMain.SetScale;
begin
  imgResized.Picture.Bitmap.Width := Round(imgOriginal.Picture.Bitmap.Width * ScaleValue);
  imgResized.Picture.Bitmap.Height := Round(imgOriginal.Picture.Bitmap.Height * ScaleValue);
  ProgressBar1.Max := imgResized.Picture.Bitmap.Height;
  ProgressBar1.Position := 0;
end;

procedure TFrmDemoMain.Splitter1Moved(Sender: TObject);
begin
  lblResizedValue.Left := ScrollBox2.Left + 6;
end;

procedure TFrmDemoMain.TrackBar1Change(Sender: TObject);
begin
  ScaleValue := TrackBar1.Position / 100;
  SetScale;
  lblScaleValue.Caption := Format('%d%%', [TrackBar1.Position]);
  lblOriginalValue.Caption := Format('Taille de l''original: %dx%d pixels', [imgOriginal.Picture.Bitmap.Width, imgOriginal.Picture.Bitmap.Height]);
  lblResizedValue.Caption := Format('Redimensionné à %s : %dx%d pixels', [lblScaleValue.Caption, imgResized.Picture.Bitmap.Width, imgResized.Picture.Bitmap.Height]);
end;

procedure TFrmDemoMain.btnSaveBitmapClick(Sender: TObject);
const nf = 'XBR_Redimensionné.bmp';
begin
  with SavePictureDialog1 do begin
    if FN = '' then FileName := nf else begin
      FileName := 'Redimensionné_'+extractFileName(FN);
    end;
    if Execute then begin
      imgResized.Picture.Bitmap.SaveToFile(FileName);
    end;
  end;
end;

procedure TFrmDemoMain.bAideClick(Sender: TObject);
begin
  NoteBook1.ActivePage := 'pageInfos';
end;

procedure TFrmDemoMain.labLienURLDblClick(Sender: TObject);
begin ShellExecute(Handle, 'OPEN', PChar(labLienURL.Caption), nil, nil, SW_SHOW);
end;

procedure TFrmDemoMain.bRetourClick(Sender: TObject);
begin
  NoteBook1.ActivePage := 'pageDéfaut';
end;

procedure TFrmDemoMain.edFlouXChange(Sender: TObject);
begin FlouX := StrToIntDef(edFlouX.text, 0)
end;

procedure TFrmDemoMain.edFlouYChange(Sender: TObject);
begin FlouY := StrToIntDef(edFlouY.text, 0)
end;

END. ///////////////////////////////////////////////////////////////////////////

