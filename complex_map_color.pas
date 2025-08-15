{$reference System.Drawing.dll}
uses System, System.Drawing, Helper;

type
  hsl = record
  private
    static procedure CheckArg(h, s, l: real);
    begin
      if (h > 360) or (h < 0) then
        raise new ArgumentOutOfRangeException('Hue', h, 'Hue must be in the range of [0..360]');
      if (s > 1) or (s < 0) then
        raise new ArgumentOutOfRangeException('Saturation', s, 'Saturation must be in the range of [0..1]');
      if (l > 1) or (l < 0) then
        raise new ArgumentOutOfRangeException('Lightness', l, 'Lightness must be in the range of [0..1]');
    end;
    
    static function HUEToRGB(v1, v2, vH: real): real;
    begin
      if (vH < 0) then
        vH += 1;
      
      if (vH > 1) then
        vH -= 1;
      
      if ((6 * vH) < 1) then
        result := (v1 + (v2 - v1) * 6 * vH) 
        else
      if ((2 * vH) < 1) then
        result := v2
        else
      if ((3 * vH) < 2) then
        result := (v1 + (v2 - v1) * ((2.0 / 3) - vH) * 6) 
      else
        result := v1;
    end;
  
  
  public
    h, s, l: real;
    constructor create(h_, s_, l_: real);
    begin
      h := h_;
      s := s_;
      l := l_;
    end;
    
    function ToRGB(): Color;
    begin
      var h:=self;
      CheckArg(h.h, h.s, h.l);
      if (h.S > 0) then
      begin
        var v1, v2: real;
        var hue := h.H / 360;
        v2 := (h.L < 0.5) ? (h.L * (1 + h.S)) : ((h.L + h.S) - (h.L * h.S));
        v1 := 2 * h.L - v2;
        result := Color.FromArgb(
        Trunc(255 * HueToRGB(v1, v2, hue + (1.0 / 3))),
        Trunc(255 * HueToRGB(v1, v2, hue)), 
        Trunc(255 * HueToRGB(v1, v2, hue - (1.0 / 3))));
      end
      else
      begin
        var r := Trunc((h.L * 255));
        result := Color.FromArgb(r, r, r);
      end;
    end;
  
  end;
  
  hsv = record
  private
    static procedure CheckArg(h, s, v: real);
    begin
      if (h > 360) or (h < 0) then
        raise new ArgumentOutOfRangeException('Hue', h, 'Hue must be in the range of [0..360]');
      if (s > 1) or (s < 0) then
        raise new ArgumentOutOfRangeException('Saturation', s, 'Saturation must be in the range of [0..1]');
      if (v > 1) or (v < 0) then
        raise new ArgumentOutOfRangeException('Lightness', v, 'Value must be in the range of [0..1]');
    end;
  
  
  public
    h, s, v: real;
    constructor create(h_, s_, v_: real);
    begin
      h := h_;
      s := s_;
      v := v_;
    end;
    
    function ToRGB(): Color;
    begin
      var h:=self;
      CheckArg(h.h, h.s, h.v);
      var r, g, b: real;
      r := 0; g := 0; b := 0;
      if (h.S > 0) then
      begin
        
        var i: integer;
        var f, p, q, t: real;
        
        if (h.H = 360) then
          h.H := 0
        else
          h.H := h.H / 60;
        
        i := Trunc(h.H);
        f := h.H - i;
        
        p := h.V * (1.0 - h.S);
        q := h.V * (1.0 - (h.S * f));
        t := h.V * (1.0 - (h.S * (1.0 - f)));
        
        case i of
          0: begin r := h.V; g := t; b := p; end;
          1: begin r := q; g := h.v; b := p; end;
          2: begin r := p; g := h.V; b := t; end;
          3: begin r := p; g := q; b := h.V; end;
          4: begin r := t; g := p; b := h.V; end
        else begin r := h.V; g := p; b := q; end;
        end;
      end else
      begin
        r := h.V;
        g := h.V;
        b := h.V;
      end;
      result := Color.FromArgb(Trunc(r * 255), Trunc(g * 255), Trunc(b * 255));
    end;
    
  end;

const
  out_name = 'color_map.png';
  width=1024;
  height=1024;

var
  PlotRegion := Helper.Region.FromSize(6);
  ImgRegion := Helper.Region.FromMinMax(0,0,width,height);


function f(z: complex) := ((z ** 2 - 1) * (z - 2 - cplx(0, 1)) ** 2) / (z ** 2 + 2 + 2 * cplx(0, 1));
//function f(z: complex) := -(z**3+z+1);
//function f(z: complex) := cplx((ln(z.Magnitude) - z.phase) * 0.5, (ln(z.Magnitude) + z.phase) * 0.5);

function NormAngle(rad: real):= rad < 0 ? 2 * pi + rad : rad;

{function ColorFunction(z, f: complex): color;
begin
  var ang := NormAngle(f.Phase);
  var mag := f.Magnitude;
  var near := power(2, ceil(log2(mag)));
  var circles := (mag * 0.6) / near + 0.4;
  var rays := Power(abs(sin(6 * f.Phase)), 0.6);
  var grid := Power(Abs(sin(Pi * f.Real) * sin(Pi * f.Imaginary)), 0.05) * 0.3 + 0.7;
  result := HSV.ToRGB(ang * 180 / pi, rays, circles * max(1 - rays, grid));
end;}
function ColorFunction(z, f: complex): color;
begin
  var ang := NormAngle(f.Phase);
  var mag := f.Magnitude;
  //var a:=1-(Power(1.000001,-mag));
  //var circles:=abs(frac(log2(a)));
  var near := power(2, ceil(log2(mag)));
  var circles := mag / near * 0.7 + 0.3;
  
  var rays := Power(abs(sin(6 * f.Phase)), 0.6);
  var grid := Power(Abs(sin(Pi * f.Real) * sin(Pi * f.Imaginary)), 0.04) * 0.6;
  
 {grid - v
  rays - s}
  //result:=HSV.ToRGB(ang*180/pi,rays,circles);
  //result:=HSV.ToRGB(ang*180/pi,rays,circles*max(1-rays,grid));
  
  result := hsl.create(RadToDeg(ang), min((rays * 2), 1), (circles * max((1 - rays) ** 1.2, grid))).ToRGB();
  {var a:=1-(Power(1.000001,-mag));
  var circles:=1-abs(frac(log2(a)))/3;
  var rays:=power(abs(sin(ang*6)),1/1);
  var grid:=Power(Abs(Sin(2* Pi * f.Real) * Sin(2 * Pi * f.Imaginary)),1/4);
  result:=HSV.ToRGB(ang*180/pi,rays,circles*grid);}
  //max(1 - rays*cirlces, grid)
  
end;

begin
  var writer := new bmp_pixels(trunc(ImgRegion.Width), trunc(ImgRegion.Height));
  for var y := 0 to height - 1 do
    for var x := 0 to width - 1 do
    begin
      var z := cplx(Region.Transofrm(ImgRegion, PlotRegion, pnt(x, y)));
      var col:=Color.Black;
       try 
        col:=ColorFunction(z, f(z));
      except
      end;
      writer.set_pixel(x,y,col);  
    end;
  writer.finish(RotateFlipType.RotateNoneFlipY).Save(out_name);
  Execute(out_name);
end.