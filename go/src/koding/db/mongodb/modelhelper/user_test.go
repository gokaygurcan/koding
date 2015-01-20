package modelhelper

import (
	"koding/db/models"
	"testing"
	"time"

	"labix.org/v2/mgo/bson"

	"github.com/koding/multiconfig"
)

type Config struct {
	MongoURL string `required:"true"`
}

func init() {
	conf := new(Config)
	multiconfig.New().MustLoad(conf)

	Initialize(conf.MongoURL)
}

func TestBlockUser(t *testing.T) {
	username, blockedReason := "testuser", "testing"

	user := &models.User{
		Name: username, ObjectId: bson.NewObjectId(), Status: UserStatusBlocked,
	}

	defer func() {
		RemoveUser(username)
	}()

	err := CreateUser(user)
	if err != nil {
		t.Error(err)
	}

	err = BlockUser(username, blockedReason, 1*time.Hour)
	if err != nil {
		t.Error(err)
	}

	user, err = GetUser(username)
	if err != nil {
		t.Error(err)
	}

	if user.Status != UserStatusBlocked {
		t.Errorf("User status is not blocked")
	}

	if user.BlockedReason != blockedReason {
		t.Errorf("User blocked reason is not: %s", blockedReason)
	}

	if user.BlockedUntil.IsZero() {
		t.Errorf("User blocked until date is not set")
	}
}

func TestRemoveUser(t *testing.T) {
	username := "testuser"
	user := &models.User{
		Name: username, ObjectId: bson.NewObjectId(),
	}

	err := CreateUser(user)
	if err != nil {
		t.Error(err)
	}

	err = RemoveUser(username)
	if err != nil {
		t.Error(err)
	}

	user, err = GetUser(username)
	if err == nil {
		t.Errorf("User should've been deleted, but wasn't")
	}
}
