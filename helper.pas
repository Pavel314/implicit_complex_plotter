{$reference WindowsBase.dll}
{$reference System.Drawing.dll}
unit helper;
uses System;
uses System.Drawing, System.Drawing.Imaging, System.Runtime.InteropServices;
type
  Point = System.Windows.Point;
  Size = System.Windows.Size;
  Vector = System.Windows.Vector;
  Vector3 = System.Numerics.Vector3;
  Vector4 = System.Numerics.Vector4;
  Matrix = System.Windows.Media.Matrix;

function pnt(x, y: real) := new Point(x, y);
function pnt(z: complex) := new Point(z.real, z.imaginary);
function cplx(p:Point):=new Complex(p.X, p.Y);

type
  ///Предполагается математическая система координат
  Region = record
  public
    x, y, Width, Height: real;
    ///x,y - координата верхнего левого угла, поэтому new Region(0,0,w,h) - построит область, которой будут принадлежать значения c отрицацельной высотой, правильно - FromMinMax(0,0,w,h)
    constructor create(x, y, width, height: real);
    begin
      self.x := x;
      self.y := y;
      self.Width := width;
      self.Height := height;
    end;
    
    ///Увеличивает ширину(высоту) прямоугольника(reg) таким образом, чтобы отношение его длин сторон соответствовало wh_rat
    function IncRatio(wh_rat: real): Region;
    begin
      if wh_rat > (Width / Height) then
      begin
        var offset := (wh_rat * Height - Width) * 0.5;
        result := FromMinMax(Left - offset, Bottom, wh_rat * Height + Left - offset, Top);    
      end else
      begin
        var offset := (Width / wh_rat - Height) * 0.5;
        result := FromMinMax(Left, Bottom - offset, Right, Width / wh_rat + Bottom - offset);
      end;
    end;
    
    function ToString():string;override;
    begin
      result:=$'X={x},Y={y},Width={Width},Height={Height}, Left={Left},Right={Right}, Top={Top},Bottom={Bottom}';
    end;
    
    //На математической системе координат задан прямоугольник.
    //Тогда его минимальные значения - нижняя левая вершина, максимальные - верхняя правая вершина
    static function FromMinMax(minX, minY, maxX, maxY: real): Region;
    begin
      var w := maxX - minX;
      var h := maxY - minY;
      result := new Region(minX, minY + h, w, h);
    end;
    
    static function FromMinMax(min, max: real) := FromMinMax(min, min, max, max);
    static function FromSize(sz: real) := FromMinMax(-sz / 2, sz / 2);
    static function FromMinToAbsMin(minX, minY: real) := FromMinMax(minx, miny, abs(minx), abs(miny));
    //static function FromCenter(centX, centY, width, height:real):=new Region(centX-width/2,centY+height/2, width, height);
    //static function FromCenter(cent, size:Point):=FromCenter(cent.X, cent.Y, size.X, size.Y);
    
    property Left: real read X;
    property Right: real read X + width;
    property Top: real read Y;
    property Bottom: real read Y - height;
    property LeftBottom: Point read pnt(Left, Bottom);
    property LeftTop: Point read pnt(Left, Top);
    property RightTop: Point read pnt(Right, Top);
    property RightBottom: Point read pnt(Right, Bottom);
    property Center: Point read pnt(X + width / 2, Y + height / 2);
    
    function Contains(p: Point) := (p.X >= Left) and (p.X <= Right) and (p.Y >= Bottom) and (p.Y <= Top);
    function DivideWH(v: real) := new Region(X, Y, width / v, height / v);
    function Move(dx, dy: real) := new Region(x + dx, y + dy, width, height);
    //function getSize() := new Size(Width, Height);
    //property Size:Size read new Size(Width, Height);
    static function GetTransformMatrix(cur, dest: Region): Matrix;
    begin
      var scaleX := dest.Width / cur.Width;
      var scaleY := dest.Height / cur.Height;
      
      var offsetX := dest.Left - cur.Left * scaleX;
      var offsetY := dest.Bottom - cur.Bottom * scaleY;
      
      //При умножение матрицы на точку происхдит такой конвеер вычислений: x/scaleX+offsetX
      //Но при преобразование точки однй области в другую правильный ответ: (x-c.left)/c.width*t.width+t.Left===
      //x*(t.width/c.width)-c.left*(c.width/t.width)+t.Left
      result := new Matrix(scaleX, 0, 0, scaleY, offsetX, offsetY);
    end;
    
    static function Transofrm(cur, dest: Region; p: Point) := new Point(  
    (p.X - cur.Left) / cur.Width * dest.Width + dest.Left,  
    (p.Y - cur.Bottom) / cur.Height * dest.Height + dest.Bottom); 
  
  end;
  
  
  
  TLine = record
  public
    p1, p2: Point;
    constructor create(p1, p2: Point);
    begin
      self.p1 := p1;
      self.p2 := p2;
    end;
  end;
  
  
  MathUtils = static class
  private
    static function CrossX(p1, p2, p3: Point; l: real): Point?;
    begin
      if (p1.Y > p2.Y) then
        swap(p1, p2);
      
      if (p1.Y = p2.Y) or ((p3.Y <= p1.Y) or ((p3.Y >= p2.Y))) then
        exit;
      
      var x := (p2.X - p1.X) * (p3.Y - p1.Y) / (p2.Y - p1.Y) + p1.X;
      if (x > p3.X + l) or (x < p3.X) then 
        exit;
      result := new Point(x, p3.y);
    end;
    
    static function CrossY(p1, p2, p3: Point; l: real): Point?;
    begin
      var swp:System.Func<Point,Point>:=v->Pnt(v.Y, v.X);
      result:=CrossX(swp(p1),swp(p2),swp(p3),l);
      if result.HasValue then
        result:=swp(result.Value);
    end;
  
  
  public
    static function MidPoint(p1, p2: Point) := new Point((p1.x + p2.x) / 2, (p1.y + p2.y) / 2);
    static function IsFinite(self: real) := (self < single.PositiveInfinity) and (self > single.NegativeInfinity);
    static function IsFinite(v: Complex) := IsFinite(v.Real) and IsFinite(V.Imaginary);
    static function IsFinite(v: Point) := IsFinite(v.X) and IsFinite(V.Y);
    
    ///Находит угол между отрезками [p1,p2] и [p2,p3]
    static function Angle(p1, p2, p3: Point): real;
    begin
      var v1 := new Vector(p1.X - p2.X, p1.Y - p2.Y);
      var v2 := new Vector(p3.X - p2.X, p3.Y - p2.Y);
      result := -Vector.Multiply(v1, v2) / (v1.Length * v2.Length);
    end;
    
    ///Находит (при наличии) точку пересечения между отрезком [p1,p2] и прямоугольником rect
    static function FindCross(p1, p2: Point; rect: Region): Point?;
    begin
      result := CrossY(p1, p2, rect.LeftBottom, rect.height);
      if (result.HasValue) then
        exit;
      result := CrossY(p1, p2, rect.RightBottom, rect.height);
      if (result.HasValue) then
        exit;
      
      result := CrossX(p1, p2, rect.LeftTop, rect.width);
      if (result.HasValue) then
        exit;
      
      result := CrossX(p1, p2, rect.LeftBottom, rect.width);
    end;
    
    static function ClipLine(p1, p2: Point; rect: Region): TLine?;
    begin
      var has_p1 := rect.Contains(p1);
      var has_p2 := rect.Contains(p2);
      if (has_p1 and has_p2) then
      begin
        result := new TLine(p1, p2);
        exit;
      end;
      if has_p1 then
      begin
        var cross := FindCross(p1, p2, rect); 
        if (cross.HasValue) then
          result := new TLine(p1, cross.Value);
      end
      else
      if has_p2 then
      begin
        var cross := FindCross(p1, p2, rect);
        if (cross.HasValue) then
          result := new TLine(p2, cross.Value);
      end
      else
      begin
        var first_clip := CrossY(p1, p2, rect.LeftBottom, rect.height);
        
        var actual_clip := CrossY(p1, p2, rect.RightBottom, rect.height);
        if (actual_clip.HasValue) then
        begin
          if (first_clip.HasValue) then
          begin
            result := new TLine(first_clip.Value, actual_clip.Value);
            exit;
          end;
          first_clip := actual_clip;
        end;
        
        actual_clip := CrossX(p1, p2, rect.LeftTop, rect.width);
        if (actual_clip.HasValue) then
        begin
          if (first_clip.HasValue) then
          begin
            result := new TLine(first_clip.Value, actual_clip.Value);
            exit;
          end;
          first_clip := actual_clip;
        end;
        
        actual_clip := CrossX(p1, p2, rect.LeftBottom, rect.width);
        if (actual_clip.HasValue) then
          result := new TLine(first_clip.Value, actual_clip.Value);
      end;
    end; 
    
    static function FindCross(l: Tline; rect: Region) := FindCross(l.p1, l.p2, rect);
    static function ClipLine(l: Tline; rect: Region) := ClipLine(l.p1, l.p2, rect); 
    static function lerp(a, b: real; t: real) := (b-a)*t+a;
    static function lerp(a, b: Complex; t: real) := (b-a)*t+a; //(z2 - z1 )* t + z1;//z1 * (1 - t) + z2 * t
    static function lerp(a, b:Vector3; t: real):=(b-a)*t+a;   //a * (1 - t) + b * t;
    static function lerp(a, b:Vector4; t: real):=(b-a)*t+a;  //a * (1 - t) + b * t;
  end;

  bmp_pixels = class(IDisposable)
  private
    bmp: Bitmap;
    data: BitmapData;
    ptr: Int64;    
  public
    constructor create(bmp_: Bitmap; do_copy: boolean := False);
    begin
      bmp := do_copy ? Bitmap(bmp_.Clone()) : bmp_;
      data := bmp.LockBits(new Rectangle(0, 0, bmp.Width, bmp.Height), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
      assert(data.Stride>=0);
      ptr := data.Scan0.ToInt64();
    end;
    
    constructor create(width_, height_: integer) := create(new Bitmap(width_, height_, PixelFormat.Format32bppArgb));
    
    property Width: integer read data.Width;
    property Height: integer read data.Height;
    
    procedure set_pixel(x, y: integer; col: Color);
    begin
      pinteger(pointer(ptr + (y * data.Stride + x * 4)))^ := col.ToArgb();
    end;
    
    procedure safe_set_pixel(x, y: integer; col: Color);
    begin
      if (x>=0) and (x<width) and (y>=0) and (y<height) then 
        set_pixel(x,y,col);
    end;
    
    function get_pixel(x, y: integer): Color;
    begin
      result := Color.FromArgb(pinteger(pointer(ptr + (y * data.Stride + x * 4)))^);
    end;
        
    function finish(rot_type:RotateFlipType := RotateFlipType.RotateNoneFlipNone): Bitmap;
    begin
      if bmp = nil then exit;
      bmp.UnlockBits(data);
      bmp.RotateFlip(rot_type);
      result := bmp;
      bmp := nil;
    end;
    
    procedure Dispose();
    begin
      finish();
    end;
  end;


begin

end. 