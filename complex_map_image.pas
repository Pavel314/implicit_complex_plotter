{$reference System.Drawing.dll}
uses System, System.Drawing, System.Drawing.Drawing2D, System.Drawing.Imaging;
uses System.Runtime.InteropServices, Helper;
// result:=((z ** 2 - 1) * (z - 2 - cplx(0, 1)) ** 2) / (z ** 2 + cplx(2, 2));
//  WorldRegion := Region.FromMinMax(-pi,-pi,pi,pi);
//  EndWorldRegion :=  Region.FromMinMax(-40,-40,40,40);
type
  ///Нормализированный цвет
  NormColor = Vector4;

function ToColor(self: NormColor): Color; extensionmethod;
begin
  result := Color.FromArgb(Trunc(self.W * 255), Trunc(self.X * 255), Trunc(self.Y * 255), Trunc(self.Z * 255));
end;

function NmColor(self: Color): NormColor;
begin
  result := new NormColor(self.R / 255, self.G / 255, self.B / 255, self.A / 255);
end;

type
  clip_uv_func = Func<Point, Point>;
  
  clip_uv_funcs = static class
  public
    static function clamp(pt: point): point;
    begin
      var x := pt.X;
      var y := pt.Y;
      if (x > 1) then x := 1 else
      if (x < 0) then x := 0;
      if (y > 1) then y := 1 else
      if (y < 0) then y := 0;
      result := new point(x, y);
    end;
    
    static function repeat_(pt: Point): Point;
    begin
      result := new Point(frac(pt.x), frac(pt.y));
      
      if (result.x < 0) then
        result.x += 1;
      
      if (result.y < 0) then
        result.y += 1;
    end;
    
    static function mirror_repeat(pt: Point): Point;
    begin
      pt.x := abs(pt.x);
      pt.y := abs(pt.y);
      result := new Point(pt.x - Math.Floor(pt.x), pt.y - Math.Floor(pt.y));
      if pt.x > Math.Floor(pt.x * 0.5) * 2 + 1 then
        result.x := 1 - result.x;
      if pt.y > Math.Floor(pt.y * 0.5) * 2 + 1 then
        result.y := 1 - result.y;
    end;
  end;
  
  
  filt_bmp = class(bmp_pixels)
  private
    texel_: Point;    
    clip_func_: clip_uv_func;
    static function old_neg_frac(v: real) := v - floor(v);
    function clamp_get(x, y: integer): Color;
    begin
      if (x >= Width) then x := Width - 1;
      if (x < 0) then x := 0;
      if (y >= Height) then y := Height - 1;
      if (y < 0) then y := 0;
      result := get_pixel(x, y);   
    end;
    
    function old_get_center(uv: point): NormColor;
    begin
      if not MathUtils.IsFinite(uv) then exit;
      var pix := clamp_get(Trunc(uv.x * (Width - 1)), Trunc(uv.y * (Height - 1)));
      result := NmColor(pix);
    end;
  
  public
    constructor create(img: Bitmap; clip_func: clip_uv_func);
    begin
      inherited create(img);
      texel_ := new Point(1 / (Width), 1 / (Height));
      clip_func_ := clip_func;
    end;
    
    property texel: Point read texel_;
    property clip_func: clip_uv_func read clip_func_;
    
    function old_get_nearset(uv: point): NormColor;
    begin
      uv := clip_func(uv);
      result := old_get_center(new Point((int(uv.x * width) + 0.5) * texel.X, (int(uv.y * height) + 0.5) * texel.Y));
    end;
    
    function old_get_bilinear(uv: point): NormColor;
    begin
      uv := clip_func(uv);
      var a := old_neg_frac((uv.x - texel.X * 0.5) * Width);
      var b := old_neg_frac((uv.y - texel.Y * 0.5) * Height);
      var p00 := new point(uv.x - a * texel.x, uv.y - b * texel.y);
      var p10 := new Point(p00.x + texel.X, p00.y);
      var p01 := new Point(p00.x, p00.y + texel.Y);
      var p11 := new Point(p00.x + texel.X, p00.y + texel.Y);
      
      var xd := MathUtils.lerp(old_get_center(p00), old_get_center(p10), a);
      var xu := MathUtils.lerp(old_get_center(p01), old_get_center(p11), a);
      result := MathUtils.lerp(xd, xu, b);
    end;
    
    function get_bilinear(uv: point): NormColor;
    begin
      uv := clip_func(uv);
      var scaled_uv := new Point(uv.X * Width - 0.5, uv.Y * Height - 0.5);
      
      var x := floor(scaled_uv.X);
      var y := floor(scaled_uv.Y);
      var diff := pnt(scaled_uv.X - x, scaled_uv.Y - y);
      
      var p00 := NmColor(clamp_get(x, y));
      var p10 := NmColor(clamp_get(x + 1, y));
      var p01 := NmColor(clamp_get(x, y + 1));
      var p11 := NmColor(clamp_get(x + 1, y + 1));
      
      var xd := MathUtils.lerp(p00, p10, diff.X);
      var xu := MathUtils.lerp(p01, p11, diff.X);
      result := MathUtils.lerp(xd, xu, diff.Y);     
    
    end;
  end;

const
  quality = 3;
  inv_func = true;
  
  in_name = 'img.jpg';
  out_name = 'img_map.png';
  clip_func = clip_uv_funcs.mirror_repeat;
  iquality = 1 / quality;

var
  FuncRegion := Region.FromMinMax(-1, 1);
  UVRegion := Region.FromMinMax(0, 1);

function f(z: complex) := 1 / z;
//Func from wiki ((z ** 2 - 1) * (z - 2 - cplx(0, 1)) ** 2) / (z ** 2 + 2 + 2 * cplx(0, 1));//z;
//Project to spehere// cplx(z.Real,-z.Imaginary)/(sqrt(1-z.Magnitude));
//Project to spehere2// cplx(z.Real,-z.Imaginary)/(sqrt(1-z.Magnitude**2));
//Plane rotate: 
{
var n:=  (z.Imaginary - OutputRegion.Bottom)/outputregion.Height;
result:=z/(1-n/2);
result:=cplx(result.Real,-result.Imaginary);}


function subdevide_px(x, y: integer; filt: filt_bmp; ImgRegion: Region): NormColor;
begin
  result := new NormColor(0);
  for var yy := 0 to quality - 1 do
    for var xx := 0 to quality - 1 do
    begin
      var p := f(cplx(Region.Transofrm(ImgRegion, FuncRegion, pnt(x + iquality * (xx + 0.5), y + iquality * (yy + 0.5)))));
      if not MathUtils.IsFinite(p) then continue; 
      var uv := Region.Transofrm(FuncRegion, UvRegion, pnt(p));
      result := result + filt.get_bilinear(uv);
    end;
  result := result / (quality * quality);
end;

function map_uv(uv: point): Point;
begin
  Result := pnt(f(cplx(Region.Transofrm(UVRegion, FuncRegion, uv))));
  Result := Region.Transofrm(FuncRegion, UvRegion, Result);
end;

begin
  var input := new Bitmap(in_name);
  var (w, h) := (input.Width, input.Height);
  var ImgRegion := Region.FromMinMax(0, 0, w, h);
  
  FuncRegion := FuncRegion.IncRatio(w / h);
  
  var reader := new filt_bmp(input, clip_func);
  var writer := new bmp_pixels(w, h);
  
  for var y := 0 to h - 1 do
  begin
    for var x := 0 to w - 1 do
    begin
      if not inv_func then
      begin
        var iuv := Region.Transofrm(ImgRegion, UVRegion, pnt(x, y));
        var ouv := map_uv(iuv); 
        if not MathUtils.IsFinite(ouv) then continue;
        var pos := Region.Transofrm(UVRegion, ImgRegion, ouv);
        writer.safe_set_pixel(trunc(pos.x), trunc(pos.y), reader.get_bilinear(iuv).ToColor())
      end else
        writer.set_pixel(x, y, subdevide_px(x, y, reader, imgRegion).ToColor());
    end;
  end;
  writer.finish(RotateFlipType.RotateNoneFlipY).Save(out_name);
  Execute(out_name);
end.