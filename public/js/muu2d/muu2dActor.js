function Actor(anims, size){
  this.anims = anims;
  this.anim = this.anims.def;
  this._size = size || new v2(50,50);
  this._orientation = new v2(1,1);
  this.t = 0;
}
Actor.prototype = new muuNode();
Actor.prototype.constructor = Actor;

Actor.prototype.size = function(size, y){
    if(typeof size === "undefined")
        return this._size;
    else if(size instanceof v2) this._size = size;
    else this._size.x =size, this._size.y = y;
    return this;
}

Actor.prototype.addAnim = function(anim, name){
    this.anims[name] = anim
    return this;
}
Actor.prototype.getAnim = function(anim){
  return this.anims[anim]
}
Actor.prototype.setAnim = function(anim){
    this.anim = this.anims[anim];
    return this;
}

Actor.prototype.orientation = function(or){
    if(typeof or === "undefined") return this._orientation;
    else this._orientation.x = or.x, this._orientation.y = or.y;
}

Actor.prototype.paintTo = function(context){
	context.translate(this.getPos().x, this.getPos().y);
	context.rotate(this.rotation());
    context.scale(this._orientation.x, this._orientation.y);
    context.translate(-this.size().x/2, -this.size().y/2)
	context.scale(this.scale(), this.scale());
	this.anim.sprite0.paintTo(context, this.size());
	context.scale(1/this.scale(), 1/this.scale());
    context.translate(this.size().x/2, this.size().y/2)
    context.scale(this._orientation.x, this._orientation.y)
    context.rotate(-this.rotation());
	context.translate(-this.getPos().x, -this.getPos().y)
}
Actor.prototype.step = function(steps){
    this.t += steps || 1
    if (this.anim.len > 1 && this.t >= this.anim.dt){
        this.t=0,anims = {dt:this.anim.dt, rand:this.anim.rand, len:this.anim.len, name:this.anim.name}
        if(this.anim.rand){
            var i = Math.floor(Math.random()*this.anim.len);
            for (var j =0; j<this.anim.len; j++)
                anims["sprite"+((i+j)%this.anim.len)] = this.anim["sprite"+j]
        } else {
        for(var i=0; i<this.anim.len-1; i++)
          anims["sprite"+i] = this.anim["sprite"+(i+1)]
        anims["sprite"+(this.anim.len-1)] = this.anim.sprite0
        }
        this.anim = anims;
    }
    if(this.t+steps>2*this.anim.dt) this.step(steps-this.anim.dt);
    return this;
}

